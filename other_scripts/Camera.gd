extends Node2D


var target
var speed = 500

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if self.position.distance_to(target.position) > 5:
		var target_dir = (target.position - self.position).normalized()
		position += speed * target_dir * delta
