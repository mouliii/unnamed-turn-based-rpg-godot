extends Node2D

onready var astar = get_node("/root/Astar")
var Bfs = load("res://other_scripts/bfs.gd")
var bfs
onready var tunnelAlgorithm = preload("res://scenes/Maps/Tunnel.tscn")
var tunnelMap
onready var MapSystem = load("res://other_scripts/ShadowCasting.gd")
var MapManager 
onready var TurnSystem = $TurnSystem
onready var fb = preload("res://scenes/SkillVisuals/Fireball.tscn")
onready var gui = $GUI
var mapData
var swordIcon = load("res://res/textures/icons/swordicon.png")

var lastMousePos = Vector2.ZERO # tile
enum {MENU, MOVE, ATTACK, SKILL, ITEM, ENDTURN, ENEMYTURN}
var Action = MOVE
var battlerIDs = []
var inCombat = false

var highlightAreaBuffer = []
var skillArea = []
var activeCharacter
var skillActivated = false
var activeSkill = null

# joku const reference _readyssä pelaajaa
# need target -spell juttu ja check ennen ondamageupdate()
# JOS SKILLI AKTIIVINEN JA ATTACK ICON NÄKYY SKIPPAANTUU VUORO
# 

func _ready():
	tunnelMap = tunnelAlgorithm.instance()
	tunnelMap.GenerateMap()
	MapManager = MapSystem.new()
	MapManager.Setup($TileMap, tunnelMap.get_child(0))
	MapManager.ResetVisionMap()
	var e = load("res://scenes/Enemy.tscn")
	var boss = e.instance()
	boss._ready()
	var bossStats = load("res://scenes/Stats/Boss.tres")
	boss.stats.initialize(bossStats)
	boss.gear.mainHand.damage = 100
	boss.get_node("Sprite").region_rect = Rect2(48,176,16,16)
	boss.position = $TileMap.map_to_world(tunnelMap.enemySpawnPoints[-1]) + $TileMap.cell_size / 2
	boss.add_to_group("enemyParty")
	TurnSystem.get_node("EnemyParty").add_child(boss)
	$TurnSystem/EnemyParty.get_child(0).stats.initialize(bossStats)
	$Camera2D.target = $TurnSystem/EnemyParty.get_child(0)
	for point in tunnelMap.GetEnemySpawnPoints().size() - 1:
		var enemy = e.instance()
		enemy.position = $TileMap.map_to_world(tunnelMap.enemySpawnPoints[point]) + $TileMap.cell_size / 2
		enemy.add_to_group("enemyParty")
		TurnSystem.get_node("EnemyParty").add_child(enemy)
	#TurnSystem.Setup()
	UpdateEntityID()
	activeCharacter = $TurnSystem/PlayerParty.get_child(0)
	TurnSystem.AddToQueue(activeCharacter)
	activeCharacter.position = $TileMap.map_to_world(tunnelMap.GetPlayerSpawnPoint()) + $TileMap.cell_size / 2
	bfs = Bfs.BFS.new($TileMap)
	$Line2D.width = 1
	# ei toimi jos on tosi ylhäällä ?
	$Camera2D.position = $TurnSystem/PlayerParty/Player.position
	$Camera2D.target = $TurnSystem/PlayerParty/Player
	var playernode = get_node("TurnSystem/PlayerParty/Player")
	playernode.connect("stepUpdate", self, "UpdateVision")
	# TODO - menee seinien läpi
	UpdateVision()
	gui.LoadShortcuts($TurnSystem/PlayerParty/Player.learnedSkills)

# aktiiviset jutut, kuten pathfind hiiren lokaatioon
func _process(_delta):
	if lastMousePos != $TileMap.world_to_map(get_global_mouse_position() ):
		lastMousePos = $TileMap.world_to_map(get_global_mouse_position() )
		match Action:
			MENU:
				pass
			MOVE:
				$Line2D.clear_points()
				var path = GetPath(activeCharacter.position, get_global_mouse_position(), 50, [])
				if path != null:
					if !path.empty():
						$Line2D.points = path
						$Line2D.add_point(activeCharacter.position, 0)
				var space = get_world_2d().direct_space_state
				var check = astar.CheckPoint($TileMap.world_to_map(get_global_mouse_position()),
											$TileMap, space, [], true)
				if "Enemy" in check:
					Input.set_custom_mouse_cursor(swordIcon)
				else:
					Input.set_custom_mouse_cursor(null)
						
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
	
# kerran tarvittavat, kuten spellin heittäminen
func _unhandled_input(event):
	var space = get_world_2d().direct_space_state
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			match Action:
				MENU:
					pass
				MOVE:
					if $TurnSystem/PlayerParty/Player.path != null:
						if !$TurnSystem/PlayerParty/Player.path.empty():
							$TurnSystem/PlayerParty/Player.StopMoving()
					$Line2D.clear_points()
					$TileMap/TargetMap.clear()
					Action = MOVE
				ATTACK:
					$TileMap/TargetMap.clear()
					Action = MOVE
				SKILL:
					$TileMap/TargetMap.clear()
					Action = MOVE
			if activeSkill != null:
					skillArea.clear()
					$TileMap/TargetMap.clear()
					activeSkill = null
		
		if event.button_index == BUTTON_LEFT and event.pressed:
			match Action:
				MOVE:
					var enemy = null
					var check = astar.CheckPoint($TileMap.world_to_map(get_global_mouse_position()),
												$TileMap, space, [], true)
					if "Enemy" in check:
						GetAttackArea()
						enemy = $TurnSystem/EnemyParty.get_node(check)
						for pos in highlightAreaBuffer:
							if pos == $TileMap.world_to_map(enemy.position):
								Action = ATTACK
								OnDamageTaken(enemy)
								EndTurn()
					# return muuten liikkuu vihun päälle
								return
						
					var characterPath
					if inCombat:
						characterPath = GetPath(activeCharacter.position, get_global_mouse_position(), 50, [])
						if !characterPath.empty():
							activeCharacter.MoveToPoint(characterPath[0], 0.05)
							EndTurn()
					else:
						characterPath = GetPath(activeCharacter.position, get_global_mouse_position(), 50, [])
						if !characterPath.empty():
							activeCharacter.Move(characterPath)
				ATTACK:
					var battlers = TurnSystem.GetCombatants()
					for areaPos in skillArea:
						for battler in battlers:
							if areaPos == $TileMap.world_to_map(battler.position):
								OnDamageTaken(battler)
								EndTurn()
								break
				SKILL:
					var battlers
					if !$TurnSystem/PlayerParty/Player.inCombat:
						for pos in skillArea:
							CheckCollision(pos, space)
					battlers = TurnSystem.GetCombatants()
					for areaPos in skillArea:
						for battler in battlers:
							if areaPos == $TileMap.world_to_map(battler.position):
								if battler.stats.hp > 0:
									OnDamageTaken(battler)
								break
					# TODO - joteki suoraan arraysta?
					for skill in activeCharacter.learnedSkills:
						if skill.name == activeSkill.name:
							skill.currentCooldown = skill.spellCooldown + 1
					#$TurnSystem/PlayerParty/Player.learnedSkills[activeSkill].currentCooldown = activeSkill.spellCooldown
					EndTurn()
		$TileMap/TargetMap.clear()
			
func GetPath(pos_in_world_from : Vector2, pos_in_world_to,steps, excludes, checkAreas = true, diagonal = true, cornerCut = false):
	var space = get_world_2d().direct_space_state
	var path = astar.astar(
	$TileMap.world_to_map(pos_in_world_from),
	$TileMap.world_to_map(pos_in_world_to), steps,
	$TileMap, space, excludes, checkAreas, diagonal, cornerCut)
	var worldPath = []
	if path != null:
		path.invert()
		path.pop_front()
		var halfCell = $TileMap.cell_size / 2
		for point in path:
			worldPath.append($TileMap.map_to_world(point) + halfCell)
	else:
		#print("F")
		return []
	return worldPath
	
func GetArea(pos_in_world : Vector2, _range, diagonal : bool, excludes, cornercut = false, collideArea2d = false):
	var space = get_world_2d().direct_space_state
	return bfs.GetArea($TileMap.world_to_map(pos_in_world), _range, diagonal, space, excludes, cornercut, collideArea2d)

func GetLine(pos_in_world : Vector2, _range, excludes, collideArea2d):
	var space = get_world_2d().direct_space_state
	return bfs.GetLine($TileMap.world_to_map(pos_in_world), _range, space, excludes, collideArea2d, battlerIDs)
	
func EndTurn():
	Action = null
	$Line2D.clear_points()
	$TileMap/TargetMap.clear()
	activeCharacter = TurnSystem.NextTurn()
	#$Camera2D.target = activeCharacter
	yield(get_tree().create_timer(0.15), "timeout")
	for _i in range(TurnSystem.waitList.size()):
		var skipTurn = false
		if activeCharacter.statusEffects.skipTurn > 0:
			skipTurn = true
		if activeCharacter.statusEffects.slow > 0:
			activeCharacter.currentAP = min(activeCharacter.currentAP + activeCharacter.AP_per_turn - 2, activeCharacter.actionPoints - 2)
		else:
			activeCharacter.currentAP = min(activeCharacter.currentAP + activeCharacter.AP_per_turn, activeCharacter.actionPoints)
		activeCharacter.statusEffects.UpdateStatusEffects()
		if activeCharacter.stats.hp <= 0:
			activeCharacter.Dead()
			activeCharacter = TurnSystem.NextTurn()
			CheckCombatState()
			continue
		if skipTurn:
			yield(get_tree().create_timer(0.5), "timeout")
			activeCharacter = TurnSystem.NextTurn()
			#$Camera2D.target = activeCharacter
		else:
			break
	for skill in activeCharacter.learnedSkills:
		if skill.currentCooldown > 0:
			skill.currentCooldown -= 1
	# TODO muuta checkPoint tjsp
	UpdateEntityID()
	if activeCharacter.is_in_group("enemyParty"):
		Action = ENEMYTURN
		# looppaa playeri tyypit
		var moveDistance
		var diagonalRange
		var nondiagonalRange
		var command
		if activeCharacter.inCombat:
			# pelaaja array vihulle -> vihu check dist
			# move - diagonal - nondiagonal
			# TODO !!!!  kun 10 raja tulee täytee nii vihu ei liiku
			$TurnSystem/PlayerParty/Player/CollisionShape2D.disabled = true
			moveDistance = GetPath(activeCharacter.position, $TurnSystem/PlayerParty/Player.position, 10, [], true)
			nondiagonalRange = GetPath(activeCharacter.position, $TurnSystem/PlayerParty/Player.position, 10, [], false, false, false)
			diagonalRange = GetPath(activeCharacter.position, $TurnSystem/PlayerParty/Player.position, 10, [], false, true, true)
			$TurnSystem/PlayerParty/Player/CollisionShape2D.disabled = false

			command = activeCharacter.CalculateTurn(moveDistance.size() - 1, diagonalRange.size(), nondiagonalRange.size() )
			match command:
				"MoveTowardsTarget":
					Action = MOVE
					activeCharacter.MoveToPoint(moveDistance.front(), 0.05)
				"AttackTarget":
					Action = ATTACK
					OnDamageTaken($TurnSystem/PlayerParty/Player)
				"Stay":
					pass
		EndTurn()
	else:
		Action = MOVE
		lastMousePos = Vector2.ZERO
		gui.UpdateHotbarCooldown()

func OnDamageTaken(target):
	randomize()
	if Action == SKILL:
		# TODO - melee ase damage mukaan ? joku 50%
		var skilldmg = floor( (activeSkill.damage * \
		(activeCharacter.stats.GetStat(activeSkill.modifierStat) * activeSkill.statDmgModifier)))
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
				var dmg = activeCharacter.gear.mainHand.damage + higherStat * 2
				var totalDmg = ceil( (dmg * dmg) / (dmg + target.stats.defence) * (1 + rand_range(0.0,0.15)) )
				target.TakeDmg(totalDmg, "damage")
			"2h":
				if activeCharacter.stats.job == "Mage":
					var dmg = activeCharacter.gear.mainHand.damage + activeCharacter.stats.intelligence * 2
					var totalDmg = ceil( (dmg * dmg) / (dmg + target.stats.defence) * (1 + rand_range(0.0,0.15)) )
					target.TakeDmg(totalDmg, "damage")
				else:
					var dmg = activeCharacter.gear.mainHand.damage + activeCharacter.stats.strength * 2.2
					var totalDmg = ceil( (dmg * dmg) / (dmg + target.stats.defence) * (1 + rand_range(0.0,0.15)) )
					target.TakeDmg(totalDmg, "damage")
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
		TurnSystem.RemoveFromQueue(target)
		CheckCombatState()

func UpdateEntityID():
	var rid
	var battlers = TurnSystem.GetAllBattlers()
	battlerIDs.clear()
	for b in battlers:
		rid = RID(b)
		battlerIDs.append(rid.get_id())

func UpdateHighlightArea(skill):
	highlightAreaBuffer.clear()
	$TileMap/TargetMap.clear()
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

func ExecuteSpecialEffect(caster, target):
	match activeSkill.specialEffect:
		"teleport":
			var path = GetPath($TurnSystem/PlayerParty/Player.position, target.position, 20, [], false )
			if path.size() > 1:
				caster.MoveToPoint(path[-2], 0)
		"charge":
			var halfCell = $TileMap.cell_size / 2
			#var path = GetLine(activeCharacter.position, activeSkill.targeting.range, [], !activeSkill.targeting.pierce)
			if skillArea.size() < activeSkill.targeting.range:
				if skillArea.size() > 1:
					caster.MoveToPoint($TileMap.map_to_world(skillArea[-2]) + halfCell, 0.35)
		_:
			print("spessu effect virhe")

func CheckEnemyLOS():
	var space = get_world_2d().direct_space_state
	var enemies = $TurnSystem/EnemyParty.get_children()
	var player = "Player"
	# for e for p if e -> p combat
	for e in enemies:
		if $TileMap.world_to_map(e.position) in MapManager.visionTiles:
			e.Draw(true)
		else:
			e.Draw(false)
		if !e.inCombat:
			if e.searchPlayer:
				# TODO - for loop kaikki playerit
				var result = space.intersect_ray(e.position, $TurnSystem/PlayerParty/Player.position, [], 1, true, true)
				if result["collider"].name == "TileMap":
					continue
				if player in result["collider"].name:
					$TurnSystem/PlayerParty/Player.inCombat = true
					$TurnSystem/PlayerParty.get_node(result["collider"].name).StopMoving()
					e.inCombat = true
					TurnSystem.AddToQueue(e)
					inCombat = true

func CheckCombatState():
	if inCombat:
		var combat = false
		var enemies = $TurnSystem/EnemyParty.get_children()
		for e in enemies:
			if e.inCombat:
				combat = true
				break
		if !combat:
			inCombat = false
			activeCharacter = $TurnSystem/PlayerParty.get_child(0)
			$TurnSystem/PlayerParty/Player.inCombat = false

func UpdateVision():
	CheckEnemyLOS()
	var space = get_world_2d().direct_space_state
	MapManager.UpdateVision($TurnSystem/PlayerParty/Player.position, $TurnSystem/PlayerParty/Player.sightRadius, space)
	if !$TurnSystem/PlayerParty/Player.inCombat:
		for skill in activeCharacter.learnedSkills:
			if skill.currentCooldown > 0:
				skill.currentCooldown -= 1
		gui.UpdateHotbarCooldown()

func GetAttackArea():
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

func SelectSpell(spell):
	# TODO - odota liikkuminen
	activeCharacter.StopMoving()
	activeSkill = spell
	UpdateHighlightArea(activeSkill)
	Action = SKILL

func CheckCollision(pos : Vector2, space):
	var check = astar.CheckPoint(pos, $TileMap, space, [], true)
	if "Enemy" in check:
		$TurnSystem/PlayerParty/Player.inCombat = true
		var enemy = $TurnSystem/EnemyParty.get_node(check)
		enemy.inCombat = true
		TurnSystem.AddToQueue(enemy)
		inCombat = true
	# if "object" in check -> brake it etc.









