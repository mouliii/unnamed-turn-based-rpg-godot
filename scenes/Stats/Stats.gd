extends Node


class_name Stats

var job : String
var hp : int
var mp : int
var maxHp : int
var maxMp : int
var strength : int
var intelligence : int
var agility : int
var defence : int
var speed :int

func initialize(stats : StartingStats):
	job = stats.job_name
	maxHp = stats.maxHp
	hp = maxHp
	maxMp = stats.maxMp
	strength = stats.strength
	intelligence = stats.intelligence
	agility = stats.agility
	defence = stats.defence
	speed = stats.speed
