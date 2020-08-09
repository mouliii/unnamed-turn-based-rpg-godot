extends Node2D

onready var astar = get_node("/root/Astar")
var Bfs = load("res://other_scripts/bfs.gd")
var bfs
onready var TurnSystem = $TurnSystem
onready var combatMenu = $CanvasLayer/CombatActions/CombatMenu
onready var skillMenu = $CanvasLayer/CombatActions/SkillList
onready var fb = preload("res://scenes/SkillVisuals/Fireball.tscn")


var lastMousePos = Vector2.ZERO # tile
enum {MENU, MOVE, ATTACK, SKILL, ITEM, ENDTURN}
var Action = MENU
var battlerIDs = []

var highlightAreaBuffer = []
var skillArea = []
var activeCharacter
var skillActivated = false
var activeSkill = null

# joku const reference _readyssä pelaajaa
# astaris, että voi mennä omien läpi
# kuolleet tyypit toiselle collision layerille ?
# need target -spell juttu ja check ennen ondamageupdate()

func _ready():
	TurnSystem.Setup()
	UpdateEntityID()
	activeCharacter = TurnSystem.GetFirstCharacater()
	bfs = Bfs.BFS.new($TileMap)
	$Line2D.width = 1
	$Camera2D.target = activeCharacter

# aktiiviset jutut, kuten pathfind hiiren lokaatioon
func _process(_delta):
	$CanvasLayer/CombatActions/CombatMenu/Label.text = str(activeCharacter.currentAP)
	if lastMousePos != $TileMap.world_to_map(get_global_mouse_position() ):
		lastMousePos = $TileMap.world_to_map(get_global_mouse_position() )
		match Action:
			MENU:
				pass
			MOVE:
				$Line2D.clear_points()
				var path = GetPath(activeCharacter.position, activeCharacter.currentAP, [])
				if path != null:
					pass
					$Line2D.points = path
					$Line2D.add_point(activeCharacter.position, 0)
			ATTACK:
				$TileMap/TargetMap.clear()
				for tile in highlightAreaBuffer:
					$TileMap/TargetMap.set_cellv(tile, 0)
				for pos in highlightAreaBuffer:
					if $TileMap.world_to_map(get_global_mouse_position()) == pos:
						skillArea = GetArea(get_global_mouse_position(), 0, 1, [], true)
						for tile in skillArea:
							$TileMap/TargetMap.set_cellv(tile, 2)
						break
					else:
						$TileMap/TargetMap.clear()
						for tile in highlightAreaBuffer:
							$TileMap/TargetMap.set_cellv(tile, 0)
			SKILL:
				for pos in highlightAreaBuffer:
					if $TileMap.world_to_map(get_global_mouse_position()) == pos:
						UpdateSkillArea(activeSkill)
						for tile in skillArea:
							$TileMap/TargetMap.set_cellv(tile, 2)
						break
					else:
						$TileMap/TargetMap.clear()
						for tile in highlightAreaBuffer:
							$TileMap/TargetMap.set_cellv(tile, 0)

# kerran tarvittavat, kuten skillin alueen aktivointi
func _unhandled_input(event):
	if event is InputEventMouseButton:
		# LINE OF SIGHT !!!!!
		if event.button_index == BUTTON_RIGHT and event.pressed:
			match Action:
				MENU:
					pass
				MOVE:
					$Line2D.clear_points()
					$TileMap/TargetMap.clear()
					Action = MENU
				ATTACK:
					$TileMap/TargetMap.clear()
					Action = MENU
				SKILL:
					$TileMap/TargetMap.clear()
					Action = MENU
			if activeSkill != null:
					skillArea.clear()
					$TileMap/TargetMap.clear()
					activeSkill = null
			if !combatMenu.visible:
				skillMenu.hide()
				combatMenu.show()
				$TileMap/TargetMap.clear()
		
		if event.button_index == BUTTON_LEFT and event.pressed:
			match Action:
				MOVE:
					var characterPath = GetPath(activeCharacter.position, activeCharacter.currentAP, [])
					activeCharacter.Move(characterPath)
					Action = MENU
					$Line2D.clear_points()
					$TileMap/TargetMap.clear()
				ATTACK:
					for pos in highlightAreaBuffer:
						if $TileMap.world_to_map(get_global_mouse_position()) == pos:
							var battlers = TurnSystem.GetCombatants()
							for areaPos in skillArea:
								for battler in battlers:
									if areaPos == $TileMap.world_to_map(battler.position):
										OnDamageTaken(battler)
										#battler.TakeDmg(activeSkill.damage)
										break
							break
					$TileMap/TargetMap.clear()
					Action = MENU
				SKILL:
					if activeCharacter.currentAP >= activeSkill.cost:
						for pos in highlightAreaBuffer:
							if $TileMap.world_to_map(get_global_mouse_position()) == pos:
								if activeSkill.name == "Fireball":
									var ball = fb.instance()
									ball.init(activeCharacter.position, get_global_mouse_position())
									add_child(ball)
									#yield(get_node("Fireball"),"tree_exited") # ei tee dmg ????
								activeCharacter.currentAP -= activeSkill.cost
								var battlers = TurnSystem.GetCombatants()
								for areaPos in skillArea:
									for battler in battlers:
										if areaPos == $TileMap.world_to_map(battler.position):
											OnDamageTaken(battler)
											#battler.TakeDmg(activeSkill.damage)
											break
								break
						$TileMap/TargetMap.clear()
						Action = MENU
			

func GetPath(pos_in_world : Vector2, steps, excludes, checkAreas = true):
	var space = get_world_2d().direct_space_state
	var path = astar.astar(
	$TileMap.world_to_map(pos_in_world),
	$TileMap.world_to_map(get_global_mouse_position()), steps,
	$TileMap, space, excludes, checkAreas)
	var worldPath = []
	if path != null:
		path.invert()
		path.pop_front()
		var halfCell = $TileMap.cell_size / 2
		for point in path:
			worldPath.append($TileMap.map_to_world(point) + halfCell)
	else:
		#print("F")
		return null
	return worldPath
	
func GetArea(pos_in_world : Vector2, _range, diagonal : bool, excludes, cornercut = false, collideArea2d = false):
	var space = get_world_2d().direct_space_state
	return bfs.GetArea($TileMap.world_to_map(pos_in_world), _range, diagonal, space, excludes, cornercut, collideArea2d)

func GetLine(pos_in_world : Vector2, _range, excludes, collideArea2d):
	var space = get_world_2d().direct_space_state
	return bfs.GetLine($TileMap.world_to_map(pos_in_world), _range, space, excludes, collideArea2d, battlerIDs)

func _on_Attack_btn_pressed():
	$TileMap/TargetMap.clear()
	match activeCharacter.gear.mainHand.handling:
		"1h":
			highlightAreaBuffer = GetArea(activeCharacter.position, 1, 1, [], true)
		"2h":
			if activeCharacter.stats.job == "Mage":
				highlightAreaBuffer = GetArea(activeCharacter.position, 4, 0, [], true)
			else:
				highlightAreaBuffer = GetArea(activeCharacter.position, 1, 1, [], true)
	highlightAreaBuffer.pop_front()
	for tile in highlightAreaBuffer:
		$TileMap/TargetMap.set_cellv(tile, 0)
	Action = ATTACK

func _on_EndTurn_btn_pressed():
	# slow vähentää max ja cur AP TODO
	Action = MENU
	$TileMap/TargetMap.clear()
	activeCharacter = TurnSystem.NextTurn()
	$Camera2D.target = activeCharacter
	for _i in range(TurnSystem.waitList.size()):
		var skipTurn = false
		if activeCharacter.statusEffects.skipTurn > 0:
			skipTurn = true
		yield(get_tree().create_timer(0.3), "timeout")
		if activeCharacter.statusEffects.slow > 0:
			activeCharacter.currentAP = min(activeCharacter.currentAP + activeCharacter.AP_per_turn - 2, activeCharacter.actionPoints - 2)
		else:
			activeCharacter.currentAP = min(activeCharacter.currentAP + activeCharacter.AP_per_turn, activeCharacter.actionPoints)
		activeCharacter.statusEffects.UpdateStatusEffects()
		if activeCharacter.stats.hp <= 0:
			activeCharacter.Dead()
			activeCharacter = TurnSystem.NextTurn()
			continue
		if skipTurn:
			yield(get_tree().create_timer(0.5), "timeout")
			activeCharacter = TurnSystem.NextTurn()
			$Camera2D.target = activeCharacter
		else:
			break
	UpdateTurnQue()
	UpdateEntityID()
	
func _on_Move_btn_pressed():
	if activeCharacter.statusEffects.root > 0:
		print("rooted, ET VOI LIIKKUA")
	else:
		Action = MOVE
		highlightAreaBuffer = GetArea(activeCharacter.position, activeCharacter.currentAP, true, [], false, true)
		for tile in highlightAreaBuffer:
			$TileMap/TargetMap.set_cellv(tile, 1)


func _on_Skills_btn_pressed():
	# delete skills from skillList
	var nButtons = skillMenu.get_children()
	for b in nButtons:
		b.remove_from_group("skillsGroup")
		b.queue_free()
	# add new skills
	for skill in activeCharacter.learnedSkills:
		combatMenu.hide()
		var button = Button.new()
		button.text = skill.name
		button.connect("pressed", self, "_on_press", [button])
		button.add_to_group("skillsGroup")
		skillMenu.add_child(button)
	combatMenu.hide()
	skillMenu.show()
	
func _on_press(button):
	activeSkill = null
	for s in activeCharacter.learnedSkills:
		if s.name == button.text:
			activeSkill = s
	if activeSkill != null:
		UpdateHighlightArea(activeSkill)
		Action = SKILL

func OnDamageTaken(target):
	randomize()
	if Action == SKILL:
		# TODO - melee ase damage mukaan ? joku 50%
		var skilldmg = floor( (activeSkill.damage * \
		( 1 + (activeCharacter.stats.GetStat(activeSkill.modifierStat) * activeSkill.statDmgModifier))) )
		var damage = ceil( (skilldmg * skilldmg) / (skilldmg + target.stats.defence) * ( 1 + rand_range(0.0, 0.15)) )
		var type = activeSkill.type
		# skill damage
		target.TakeDmg(damage, type)
		if !activeSkill.statusEffect.empty():
			var statusChance = activeSkill.statusEffect.applyChance
			if statusChance != 0 or statusChance != null:
				var rng = randf()
				if rng < statusChance:
					if activeSkill.has("specialEffect"):
						ExecuteSpecialEffect(activeCharacter, target)
					print("status afflicted!")
					target.statusEffects.AddEffect(activeSkill.statusEffect, damage)
	elif Action == ATTACK:
		var higherStat
		var stat1 = activeCharacter.stats.strength
		var stat2  = activeCharacter.stats.agility
		if stat1 > stat2:
			higherStat = stat1
		else:
			higherStat = stat2
		match activeCharacter.gear.mainHand.handling:
			"1h":
				if activeCharacter.currentAP >= activeCharacter.gear.mainHand.cost:
					var dmg = activeCharacter.gear.mainHand.damage + higherStat * 2
					var totalDmg = ceil( (dmg * dmg) / (dmg + target.stats.defence) * (1 + rand_range(0.0,0.15)) )
					target.TakeDmg(totalDmg, "damage")
					activeCharacter.currentAP -= activeCharacter.gear.mainHand.cost
			"2h":
				if activeCharacter.currentAP >= activeCharacter.gear.mainHand.cost:
					if activeCharacter.stats.job == "Mage":
						var dmg = activeCharacter.gear.mainHand.damage + activeCharacter.stats.intelligence * 2
						var totalDmg = ceil( (dmg * dmg) / (dmg + target.stats.defence) * (1 + rand_range(0.0,0.15)) )
						target.TakeDmg(totalDmg, "damage")
					else:
						var dmg = activeCharacter.gear.mainHand.damage + activeCharacter.stats.strength * 2.2
						var totalDmg = ceil( (dmg * dmg) / (dmg + target.stats.defence) * (1 + rand_range(0.0,0.15)) )
						target.TakeDmg(totalDmg, "damage")
					activeCharacter.currentAP -= activeCharacter.gear.mainHand.cost
			"bow":
				# agi?
				pass
		# tähä varmaa delay jos dual attack
		if activeCharacter.gear.offHand != null:
			match activeCharacter.gear.offHand.handling:
				"1h":
					yield(get_tree().create_timer(0.2), "timeout")
					var dmg = activeCharacter.gear.mainHand.damage + higherStat * 1.8
					var totalDmg = (dmg * dmg) / (dmg + target.stats.defence)
					target.TakeDmg(totalDmg, "damage")
	if target.stats.hp <= 0:
			if activeCharacter == TurnSystem.GetCurrentCharacter():
				# TODO - override methodin jälkee  --- siis override endturn
				Action = ENDTURN
			TurnSystem.RemoveFromQueue(target)
			UpdateTurnQue()

func UpdateTurnQue():
	var delete = $CanvasLayer/TurnOrder.get_children()
	for d in delete:
		d.queue_free()
	var turns = TurnSystem.TurnOrder()
	for turn in turns:
		var text = Label.new()
		text.text = turn
		$CanvasLayer/TurnOrder.add_child(text)

func UpdateEntityID():
	var rid
	var battlers = TurnSystem.GetAllBattlers()
	battlerIDs.clear()
	for b in battlers:
		rid = RID(b)
		battlerIDs.append(rid.get_id())

func UpdateHighlightArea(skill):
	highlightAreaBuffer.clear()
	match skill.targeting.type:
		"ranged":
			highlightAreaBuffer = GetArea(activeCharacter.position, activeSkill.targeting.range,
						activeSkill.targeting.diagonal, [], true)
			for tile in highlightAreaBuffer:
				$TileMap/TargetMap.set_cellv(tile, 0)
		"line":
			#var battlers = TurnSystem.GetCombatants()
			var multiarray = GetLine(activeCharacter.position, activeSkill.targeting.range, [], !activeSkill.targeting.pierce)
			for i in range(multiarray.size()):
				for j in multiarray[i]:
					highlightAreaBuffer.append(j)
			for tile in highlightAreaBuffer:
				$TileMap/TargetMap.set_cellv(tile, 0)

func UpdateSkillArea(skill):
	$TileMap/TargetMap.clear()
	for tile in highlightAreaBuffer:
		$TileMap/TargetMap.set_cellv(tile, 0)
	match skill.targeting.type:
		"ranged":
			skillArea = GetArea(get_global_mouse_position(),
				activeSkill.targeting.splashRange, activeSkill.targeting.diagonal, [], true, false)
		"line":
			var index = -1
			var multiarray = GetLine(activeCharacter.position, activeSkill.targeting.range, [], !activeSkill.targeting.pierce)
			for i in range(multiarray.size()):
				for j in multiarray[i]:
					if $TileMap.world_to_map(get_global_mouse_position()) == j:
						index = i
						break
				if index != -1:
					break
			skillArea = multiarray[index]
	if !activeSkill.selfTarget:
		for tile in skillArea:
			if $TileMap.world_to_map(activeCharacter.position) == tile:
				skillArea.erase(tile)

func ExecuteSpecialEffect(caster, _target):
	match activeSkill.specialEffect:
		"teleport":
			var path = GetPath(activeCharacter.position, 20, [], false )
			if path.size() > 1:
				caster.MoveToPoint(path[-2], 0)
		"charge":
			var halfCell = $TileMap.cell_size / 2
			#var path = GetLine(activeCharacter.position, activeSkill.targeting.range, [], !activeSkill.targeting.pierce)
			if skillArea.size() < activeSkill.targeting.range:
				caster.MoveToPoint($TileMap.map_to_world(skillArea[-2]) + halfCell, 0.35)
		_:
			print("spessu effect virhe")







