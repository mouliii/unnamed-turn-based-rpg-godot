extends Area2D

onready var tween = $Tween
onready var HpBar = $HPBar
var floatingText = preload("res://scenes/FloatingText.tscn")
export var animationSpeed = 20
export var startingStats : Resource

var path = []

enum {IDLE, MOVING, ATTACKING}
var state = IDLE

onready var stats = $Job/Stats
onready var skillManager = $Job/SkillManager
var learnedSkills
var actionPoints = 6  # <--- statteihi ?
var currentAP = actionPoints

func _ready():
	stats.initialize(startingStats)
	learnedSkills = skillManager.learnedSkills
	skillManager.LearnSkill("Attack")
	HpBarUpdate()
	match stats.job:
		"Warrior":
			$Sprite.set_region_rect(Rect2(96,139,16,21))
			skillManager.LearnSkill("Whirlwind")
		"Mage":
			$Sprite.set_region_rect(Rect2(81,143,14,17))
			skillManager.LearnSkill("Fire")
			skillManager.LearnSkill("Heal")
		"Rogue":
			$Sprite.set_region_rect(Rect2(50,160,12,17))
			skillManager.LearnSkill("Stab")
			skillManager.LearnSkill("Bow")
		_:
			$Sprite.set_region_rect(Rect2(96,139,16,21))

func _process(_delta):
	
	match state:
		IDLE:
			pass
		MOVING:
			if not path.empty():
				tween.interpolate_property(self, "position", position, path.front(), 1.0 / animationSpeed,
				Tween.TRANS_SINE, Tween.EASE_IN_OUT)
				if position.distance_to(path.front()) < 5:
					path.pop_front()
			if not tween.is_active():
				state = IDLE
		ATTACKING:
			pass
		_:
			pass
	
func Move(_path):
	path = _path
	if path != null:
		ReduceAP(path.size())
		state = MOVING
		tween.interpolate_property(self, "position", position, path.front(), 1.0 / animationSpeed,
		Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		tween.start()
func StopMoving():
	pass

func PlayAttackAnim(_skill : String):
	ReduceAP(2)
	print("fiuf miekka löi")

func ReduceAP(val):
	currentAP -= val

func TakeDmg(damage : int):
	# floating combat text
	var floatText = floatingText.instance()
	floatText.damage = damage
	add_child(floatText)
	# -hp
	stats.hp = max(stats.hp - damage, 0)
	print(stats.job + " otti damagee " + str(damage) + ", hp: " + str(stats.hp))
	# hp bar update
	HpBarUpdate()
	if stats.hp == 0:
		Dead()

func Dead():
	HpBar.hide()
	$Sprite.rotate(90)

func HpBarUpdate():
	var hp_p = int(( float(stats.hp) / stats.maxHp) * 100)
	HpBar.value = hp_p









