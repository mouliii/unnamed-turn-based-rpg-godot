extends Area2D

onready var tween = $Tween
var from : Vector2
var to : Vector2

func init(from_, to_):
	from = from_
	to = to_
	position = from
# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("travel")
	$Sprite.rotate(from.angle_to(to))
	tween.interpolate_property(self, "position", position, to, 0.2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()

func _on_Tween_tween_completed(_object, key):
	if key == ":position":
		$AnimationPlayer.play("explosion")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "explosion":
		self.queue_free()
