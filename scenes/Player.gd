extends Area2D

signal stepUpdate

onready var tween = $Tween
onready var HpBar = $HPBar
var floatingText = preload("res://scenes/FloatingText.tscn")
export var startingStats : Resource

var path = []

enum {IDLE, MOVING, ATTACKING}
var state = IDLE

onready var stats = $Job/Stats
onready var skillManager = $Job/SkillManager
onready var statusEffects = $Job/StatusEffects
onready var gear = $Job/Gear
var learnedSkills
var actionPoints = 6  # <--- statteihi ?
var currentAP = actionPoints
var AP_per_turn = 4
var inCombat = false
var sightRadius = 10

func _ready():
	rotation_degrees = 0
	stats.initialize(startingStats)
	learnedSkills = skillManager.learnedSkills
	var armors = gear.EquidBasicArmor()
	gear.AddStatsFromGear(armors["warrior"]["mainHand"])
	match stats.job:
		"Warrior":
			$Sprite.set_region_rect(Rect2(96,139,16,21))
			skillManager.LearnSkill("Whirlwind")
			skillManager.LearnSkill("Storm bolt")
			skillManager.LearnSkill("Charge")
			for g in armors["warrior"]:
				gear.EquipGear(armors["warrior"][g], g)
		"Mage":
			$Sprite.set_region_rect(Rect2(81,143,14,17))
			skillManager.LearnSkill("Fireball")
			skillManager.LearnSkill("Entangling Roots")
			skillManager.LearnSkill("Sandstorm")
			for g in armors["mage"]:
				gear.EquipGear(armors["mage"][g], g)
		"Rogue":
			$Sprite.set_region_rect(Rect2(50,160,12,17))
			skillManager.LearnSkill("Stab")
			skillManager.LearnSkill("Power Shot")
			skillManager.LearnSkill("Shadowstep")
			for g in armors["rogue"]:
				gear.EquipGear(armors["rogue"][g], g)
		_:
			$Sprite.set_region_rect(Rect2(96,139,16,21))
	stats.hp = stats.maxHp
	HpBarUpdate()
	
func _process(_delta):
	
	match state:
		IDLE:
			pass
		MOVING:
			if not path.empty():
				$AnimationPlayer.play("walk")
				tween.interpolate_property(self, "position", position, path.front(), 0.05, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
				if position.distance_to(path.front()) < 5:
					emit_signal("stepUpdate")
					path.pop_front()
			if not tween.is_active():
				state = IDLE
		ATTACKING:
			pass
		_:
			pass
	
func Move(_path):
	path = _path
	if path != null or !path.empty():
		state = MOVING
		tween.interpolate_property(self, "position", position, path.front(), 0.05, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		tween.start()

func MoveToPoint(point, time):
	path.clear()
	state = MOVING
	tween.interpolate_property(self, "position", position, point, time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	#emit_signal("stepUpdate")
	tween.start()

func StopMoving():
	if path != null or !path.empty():
		var pathfront = path[0]
		path.clear()
		path.append(pathfront)

func PlayAttackAnim(_skill : String):
	pass

func ReduceAP(val):
	currentAP -= val

func TakeDmg(damage : int, type : String):
	var dmgToTake = (damage * damage) / (damage + stats.defence)
	if type == "hot" or type == "heal":
		stats.hp += dmgToTake
	elif type == "dot" or type == "damage":
		stats.hp -= dmgToTake
	# hp bar update
	HpBarUpdate()
	if stats.hp <= 0:
		Dead()
	# direct dmg
	if type == "damage":
		print(stats.job + " otti damagee " + str(damage) + ", hp: " + str(stats.hp))
	elif type == "heal":
		print(stats.job + " healas damagee " + str(damage) + ", hp: " + str(stats.hp))
	# dots
	match type:
		"dot":
			print(stats.job + " otti damagee " + str(damage) + ", hp: " + str(stats.hp))
		"hot":
			print(stats.job + " healas damagee " + str(damage) + ", hp: " + str(stats.hp))
	# floating combat text
	var floatText = floatingText.instance()
	floatText.damage = damage
	floatText.type = type
	add_child(floatText)

func Dead():
	HpBar.hide()
	var rand = randi() % 10
	if rand < 5:
		$Sprite.rotate(90)
	else:
		$Sprite.rotate(-90)

func HpBarUpdate():
	var hp_p = int(( float(stats.hp) / stats.maxHp) * 100)
	HpBar.value = hp_p

func _on_Tween_tween_all_completed():
	$AnimationPlayer.stop()
	rotation_degrees = 0
	emit_signal("stepUpdate")
