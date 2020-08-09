extends Node


class_name StatusEffects

func CreateStatus(statusEffect, baseDmg):
	var effect = statusEffect.duplicate(true)
	if not effect.empty():
		if !effect.entryEffect.empty():
				match effect.entryEffect[0]:
					"dot":
						effect.entryEffect[1] = ceil(baseDmg * statusEffect.entryEffect[1])
					"hot":
						effect.entryEffect[1] = ceil(baseDmg * statusEffect.entryEffect[1])
		if !effect.tickEffect.empty():
			effect.tickEffect[1] = ceil(baseDmg * statusEffect.tickEffect[1])
		if !effect.onLeaveEffect.empty():
			effect.onLeaveEffect[1] = ceil(baseDmg * statusEffect.onLeaveEffect[1])
		return effect

	
"""
	"name": "Burn"
	"IsBeneficial": 0
	"entryEffect": ["dot", 1.5]
	"tickEffect": ["dot", 0.2]
	"onLeaveEffect":["hot", 1.0]
	"turns": 3
"""
