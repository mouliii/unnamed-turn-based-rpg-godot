extends "res://other_scripts/StatusEffects.gd"

var buffs = []
var debuffs = []
var slow = int(0)
var root = int(0)
var skipTurn = int(0)

func AddEffect(effect, dmg):
	var status = CreateStatus(effect, dmg)
	if status.isBeneficial:
		buffs.append(status)
	else:
		debuffs.append(status)
	if !status.entryEffect.empty():
		match status.entryEffect[0]:
			"dot":
				get_parent().get_parent().TakeDmg(status.entryEffect[1], status.entryEffect[0])
			"hot":
				get_parent().get_parent().TakeDmg(status.entryEffect[1], status.entryEffect[0])
			"stun":
				skipTurn += status.entryEffect[1]
			"root":
				root += status.entryEffect[1]
			"slow":
				slow += status.entryEffect[1]

func UpdateStatusEffects():
	# vika tik on onleaveeffect jos on, muuten vika tik tik tik
	UpdateEffects()
	for effect in buffs:
		effect.turns -= 1
		if effect.turns < 0:
			buffs.erase(effect)
			continue
		elif effect.turns == 0:
			if !effect.onLeaveEffect.empty():
				get_parent().get_parent().TakeDmg(effect.onLeaveEffect[1], effect.onLeaveEffect[0])
			else:
				get_parent().get_parent().TakeDmg(effect.tickEffect[1], effect.tickEffect[0])
	for effect in debuffs:
		effect.turns -= 1
		
		if effect.turns == 0:
			if !effect.onLeaveEffect.empty():
				match effect.onLeaveEffect[0]:
					"dot":
						get_parent().get_parent().TakeDmg(effect.onLeaveEffect[1], effect.onLeaveEffect[0])
					"hot":
						get_parent().get_parent().TakeDmg(effect.onLeaveEffect[1], effect.onLeaveEffect[0])
			else:
				if !effect.tickEffect.empty():
					match effect.tickEffect[0]:
						"dot":
							get_parent().get_parent().TakeDmg(effect.tickEffect[1], effect.tickEffect[0])
						"hot":
							get_parent().get_parent().TakeDmg(effect.tickEffect[1], effect.tickEffect[0])
		if effect.turns <= 0:
			debuffs.erase(effect)
		else:
			if !effect.tickEffect.empty():
				match effect.tickEffect[0]:
					"dot":
						get_parent().get_parent().TakeDmg(effect.tickEffect[1], effect.tickEffect[0])
					"hot":
						get_parent().get_parent().TakeDmg(effect.tickEffect[1], effect.tickEffect[0])
#					"stun":
#							pass
#					"root":
#						pass
#					"slow":
#						pass

func UpdateEffects():
	skipTurn = max(skipTurn - 1, 0)
	root = max(root - 1, 0)
	slow = max(slow - 1, 0)
	
	"""
	"name": "Burn"
	"isBeneficial": 0
	"entryEffect": ["dot", 1.5]
	"tickEffect": ["dot", 0.2]
	"onLeaveEffect":["hot", 1.0]
	"turns": 3
"""
