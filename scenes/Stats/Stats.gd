extends Node


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


func GetStat(stat):
	var stats = {"agility":agility, "strength": strength, "intelligence": intelligence, 
				"hp": hp, "maxHp": maxHp, "defence": defence, "speed": speed}
	return stats.get(stat)

func GetAllStats():
	var stats = {"agility":agility, "strength": strength, "intelligence": intelligence, 
				"hp": hp, "maxHp": maxHp, "defence": defence, "speed": speed}
	return stats

func AddStat(stat, value):
	var stats = {"agility":agility, "strength": strength, "intelligence": intelligence, 
				"hp": hp, "maxHp": maxHp, "defence": defence, "speed": speed}
	stats[stat] += value

func RemoveStat(stat, value):
	var stats = {"agility":agility, "strength": strength, "intelligence": intelligence, 
				"hp": hp, "maxHp": maxHp, "defence": defence, "speed": speed}
	stats[stat] -= value

func GetHighestPrimaryStat():
	var stat = ["",0]
	if agility > stat[1]:
		stat = ["agility",agility]
	if strength > stat[1]:
		stat = ["strength",strength]
	if intelligence > stat[1]:
		stat = ["intelligence",intelligence]
	return stat









