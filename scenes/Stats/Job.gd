extends Node

class_name Job

onready var stats = $Stats
onready var skills = $SkillManager

export var starting_stats : Resource

#var learnedSkills = []

func _ready():
	pass
	#stats.initialize(starting_stats)
	# kokeilu parent node readssä
