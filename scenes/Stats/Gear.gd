extends Node

var mainHand = null
var offHand = null
var headArmor = null
var chestArmor = null
var legArmor = null


func EquipGear(gear, slot):
	match slot:
		"mainHand":
			mainHand = gear
			AddStatsFromGear(gear)
		"offHand":
			offHand = gear
			AddStatsFromGear(gear)
		"headArmor":
			headArmor = gear
			AddStatsFromGear(gear)
		"chestArmor":
			chestArmor = gear
			AddStatsFromGear(gear)
		"legArmor":
			legArmor = gear
			AddStatsFromGear(gear)
		_:
			print("ei ole tuollaista gearia")
			
func UnEquipGear(slot):
	match slot:
		"mainHand":
			RemoveAddedStatsFromGear(mainHand)
		"offHand":
			RemoveAddedStatsFromGear(offHand)
		"headArmor":
			RemoveAddedStatsFromGear(headArmor)
		"chestArmor":
			RemoveAddedStatsFromGear(chestArmor)
		"legArmor":
			RemoveAddedStatsFromGear(legArmor)
		_:
			print("ei ole tuollaista gearia")

func EquidBasicArmor():
	var armors = {
		"warrior":{
		"headArmor":{"armor": 12, "strength": 1, "hp": 37},
		"chestArmor": {"armor": 25, "strength": 2, "hp": 75},
		"legArmor": {"armor": 13, "strength": 1, "hp": 38},
		"mainHand": {"damage": 100, "handling": "2h", "type": "sword", "range": 1, "strength": 3, "hp": 20}
		},
		"mage":{
		"headArmor":{"armor": 12, "intelligence":1, "hp": 37},
		"chestArmor": {"armor": 25, "intelligence":2, "hp": 75},
		"legArmor": {"armor": 13, "intelligence":1, "hp": 38},
		"mainHand": {"damage": 20, "handling": "2h", "type": "staff", "range": 1, "intelligence":3, "hp": 20}
		},
		"rogue":{
		"headArmor":{"armor": 12, "agility": 1, "hp": 37},
		"chestArmor": {"armor": 25, "agility": 2, "hp": 75},
		"legArmor": {"armor": 13, "agility": 1, "hp": 38},
		"mainHand": {"damage": 15, "handling": "1h", "type": "dagger", "range": 1, "agility": 1, "hp": 10},
		"offHand": {"damage": 15, "handling": "1h", "type": "dagger", "range": 1, "agility": 1, "hp": 5}
		}
	}
	return armors

func AddStatsFromGear(gear):
	var stats = get_parent().get_parent().stats
	for stat in stats.GetAllStats():
		if gear.has(stat):
			stats.AddStat(stat, gear[stat])
	
func RemoveAddedStatsFromGear(gear):
	var stats = get_parent().get_parent().stats
	for stat in stats.GetAllStats():
		if gear.has(stat):
			stats.RemoveStat(stat, gear[stat])
