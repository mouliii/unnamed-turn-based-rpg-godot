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
				print(next.stats.job)
				return waitList.front()
	else:
		waitList = GetCombatants()
		return waitList.front()
		
func Setup():
	var nChild = get_child_count()
	for n in nChild:
		var characters = get_child(n).get_children()
		for c in characters:
			if c.stats.hp > 0:
				waitList.append(c)
	waitList.sort_custom(self, "custom_array_sort")
	
func custom_array_sort(a , b):
	if a.stats.speed > b.stats.speed:
		return a > b

func GetFirstCharacater():
	if not waitList.empty():
		return waitList.front()
	else:
		print("et oo setupannu")

func GetCombatants():
	var battlers = []
	var nChild = get_child_count()
	for n in nChild:
		var characters = get_child(n).get_children()
		for c in characters:
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




