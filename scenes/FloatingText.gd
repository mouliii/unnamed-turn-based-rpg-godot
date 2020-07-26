extends Position2D


onready var text = $Label
onready var tween = $Tween
var damage = 0
var type = ""
var velocity = Vector2.ZERO

func _ready():
	
	# TODO critit yms.
	match type:
		"damage":
			text.set("custom_colors/font_color", Color("ff3131"))
		"heal":
			text.set("custom_colors/font_color", Color("2eff27"))
	
	randomize()
	var rand = randi() % 40-20
	velocity = Vector2(rand, 30)

	text.text = str(damage)
	tween.interpolate_property(self, "scale", scale, Vector2(1.2,1.2), 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.interpolate_property(self, "scale", Vector2(1.2,1.2), Vector2(0.5,0.5), 0.4, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.3)
	tween.start()

func _process(delta):
	position -= velocity * delta
func _on_Tween_tween_all_completed():
	self.queue_free()
