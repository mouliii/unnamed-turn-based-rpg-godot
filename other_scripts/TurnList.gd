extends Node2D

var waitList = []
var usedList = []

func NextTurn():
	usedList.append(waitList.front())
	waitList.pop_front()
	if not waitList.empty():
		for character in waitList:
			var next = waitList.front()
			if next.stats.hp <= 0:
				usedList.append(next)
				waitList.pop_front()
			else:
				return waitList.front()
	else:
		waitList = GetCombatants()
		waitList.sort_custom(self, "custom_array_sort")
		return waitList.front()
		
func Setup():
	var nChild = get_child_count()
	for n in nChild:
		var characters = get_child(n).get_children()
		for c in characters:
			if !c.inCombat:
				continue
			if c.stats.hp > 0:
				waitList.append(c)
	waitList.sort_custom(self, "custom_array_sort")
	
func custom_array_sort(a , b):
	return a.stats.speed > b.stats.speed

func GetFirstCharacater():
	if not waitList.empty():
		return waitList.front()
	else:
		print("et oo setupannu")

func GetCombatants():
	var battlers = []
	battlers.append($PlayerParty/Player)
	var goodguys = get_child(0).get_children()
	for c in range(1,goodguys.size()):
		if !goodguys[c].inCombat:
			continue
		if goodguys[c].stats.hp > 0:
			battlers.append(goodguys[c])
	var badguys = get_child(1).get_children()
	for c in badguys:
		if !c.inCombat:
			continue
		if c.stats.hp > 0:
			battlers.append(c)
	return battlers

func TurnOrder():
	var order = []
	for c in waitList:
		order.append(c.stats.job)
	return order

func RemoveFromQueue(character):
	if character in waitList:
		waitList.erase(character)

func GetCurrentCharacter():
	if !waitList.empty():
		return waitList[0]

func GetAllBattlers():
	var battlers = []
	var nChild = get_child_count()
	for n in nChild:
		var characters = get_child(n).get_children()
		for c in characters:
			battlers.append(c)
	return battlers

func AddToQueue(character):
	waitList.append(character)








