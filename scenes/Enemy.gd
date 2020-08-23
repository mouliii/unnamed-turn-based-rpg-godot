extends Area2D

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
onready var aggroArea = $aggro_area
var learnedSkills
var actionPoints = 6  # <--- statteihi ?
var currentAP = actionPoints
var AP_per_turn = 4
var inCombat = false
var searchPlayer = false

func _ready():
	rotation_degrees = 0
	var s = load("res://scenes/Stats/vihu.tres")
	stats.initialize(s)
	learnedSkills = skillManager.learnedSkills
	stats.hp = stats.maxHp
	HpBarUpdate()
	gear.EquipGear(armors["headArmor"], "headArmor")
	gear.EquipGear(armors["chestArmor"], "chestArmor")
	gear.EquipGear(armors["legArmor"], "legArmor")
	gear.EquipGear(armors["mainHand"], "mainHand")
	
func _process(_delta):
	match state:
		IDLE:
			pass
		MOVING:
			if not path.empty():
				$AnimationPlayer.play("walk")
				tween.interpolate_property(self, "position", position, path.front(), 0.05, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
				if position.distance_to(path.front()) < 5:
					path.pop_front()
			if not tween.is_active():
				state = IDLE
		ATTACKING:
			pass
		_:
			pass
	
func CalculateTurn(moveDistance, diagonalDistance, _nondiagonalDistance):
	if inCombat:
		if diagonalDistance <= gear.mainHand.range:
			return "AttackTarget"
		if moveDistance > 10:
			return "Stay"
		elif moveDistance > 0 and moveDistance < 10:
			if statusEffects.root > 0:
				return "Stay"
			else:
				return "MoveTowardsTarget"
	else:
		pass
#MoveAndAttack
#RangedMoveAndAttack
#SpellCasterBehaviour
#RunAwayAndAlertBehaviour

func _on_aggro_area_area_entered(area):
	var type = "Player"
	if type in area.get_name():
		searchPlayer = true


func _on_aggro_area_area_exited(area):
	var type = "Player"
	if type in area.get_name():
		searchPlayer = false


func Move(_path):
	path = _path
	if path != null:
		state = MOVING
		tween.interpolate_property(self, "position", position, path.front(), 0.05, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		tween.start()

func MoveToPoint(point, time):
	path.clear()
	state = MOVING
	tween.interpolate_property(self, "position", position, point, time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()

func StopMoving():
	if path != null:
		var pathfront = path[0]
		path.clear()
		path.append(pathfront)

func PlayAttackAnim(_skill : String):
	pass

func ReduceAP(val):
	currentAP -= val

func TakeDmg(damage : int, type : String):
	#var dmgToTake = (damage * damage) / (damage + stats.defence)
	if type == "hot" or type == "heal":
		stats.hp += damage
	elif type == "dot" or type == "damage":
		stats.hp -= damage
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
	$aggro_area/CollisionShape2D.disabled = true
	$CollisionShape2D.disabled = true
	searchPlayer = false
	
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

var armors = {
		"headArmor":{"armor": 0, "strength": 1, "hp": 0},
		"chestArmor": {"armor": 15, "strength": 2, "hp": 50},
		"legArmor": {"armor": 10, "strength": 1, "hp": 20},
		"mainHand": {"damage": 50, "handling": "2h", "type": "club", "range": 1, "strength": 3, "hp": 20}
		}

func Draw(canSee : bool):
	if canSee:
		$Sprite.show()
	else:
		$Sprite.hide()









