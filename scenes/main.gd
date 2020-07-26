extends Node2D

onready var astar = get_node("/root/Astar")
var Bfs = load("res://other_scripts/bfs.gd")
var bfs
onready var TurnSystem = $TurnSystem
onready var combatMenu = $CanvasLayer/CombatActions/CombatMenu
onready var skillMenu = $CanvasLayer/CombatActions/SkillList

var lastMousePos = Vector2.ZERO # tile
enum {MENU, MOVE, ATTACK, ITEM, ENDTURN}
var Action = MENU

var highlightAreaBuffer = []
var skillArea = []
var activeCharacter
var skillActivated = false
var activeSkill = null

# joku const reference _readyssä pelaajaa
# astaris kattoo jos hiiri ei oo liikkunu nii ei tarvii turhaa laskee joka frame
# astaris memory leak ??? ei tietoo <-- korjattu tekemällä space.check_point(hiiri), näyttäs toimiva
# astaris, että voi mennä omien läpi

func _ready():
	TurnSystem.Setup()
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
				for pos in highlightAreaBuffer:
					if $TileMap.world_to_map(get_global_mouse_position()) == pos:
						# en tiiä miks tällee pitää tehä mut tää toimii vvvvvvvv
						if $TileMap.world_to_map(get_global_mouse_position()) == $TileMap.world_to_map(activeCharacter.position):
							$TileMap/TargetMap.clear()
							for tile in highlightAreaBuffer:
								$TileMap/TargetMap.set_cellv(tile, 0)
						var exclude = Vector2.ZERO
						if activeSkill.selfTarget:
							exclude = $TileMap.world_to_map(activeCharacter.position)
						skillArea = GetArea(get_global_mouse_position(),
							activeSkill.splashRange, activeSkill.diagonal, [], exclude, false, false)
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
			# TODO vvvvvvv
			if activeSkill != null:
					skillArea.clear()
					$TileMap/TargetMap.clear()
					activeSkill = null
			if !combatMenu.visible:
				skillMenu.hide()
				combatMenu.show()
				$TileMap/TargetMap.clear()
		
		if event.button_index == BUTTON_LEFT and event.pressed:
			if activeCharacter.currentAP > 0:
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
								activeCharacter.PlayAttackAnim("auto attack")
								var battlers = TurnSystem.GetCombatants()
								if !activeSkill.selfTarget:
									skillArea.pop_front()
								for areaPos in skillArea:
									for battler in battlers:
										if areaPos == $TileMap.world_to_map(battler.position):
											
											# spalsh dmg
											OnDamageTaken(battler, activeSkill.damage)
											#battler.TakeDmg(activeSkill.damage)
											break
								break
						$TileMap/TargetMap.clear()
						Action = MENU
			

func GetPath(pos_in_world : Vector2, steps, excludes):
	var space = get_world_2d().direct_space_state
	var path = astar.astar(
	$TileMap.world_to_map(pos_in_world),
	$TileMap.world_to_map(get_global_mouse_position()), steps,
	$TileMap, space, excludes)
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
	
func GetArea(pos_in_world : Vector2, _range, diagonal : bool, excludes, selfTarget = null, cornercut = false, collideArea2d = false):
	var space = get_world_2d().direct_space_state
	return bfs.GetArea($TileMap.world_to_map(pos_in_world), _range, diagonal, space, excludes, selfTarget, cornercut, collideArea2d)
	

func _on_Attack_btn_pressed():
	if activeCharacter.currentAP >= 2:
		Action = ATTACK
		$Line2D.clear_points() # TODO --------------------->v
	highlightAreaBuffer = GetArea(activeCharacter.position, 1, false, [])
	for tile in highlightAreaBuffer:
		$TileMap/TargetMap.set_cellv(tile, 0)

func _on_EndTurn_btn_pressed():
	Action = MENU
	$TileMap/TargetMap.clear()
	activeCharacter = TurnSystem.NextTurn()
	yield(get_tree().create_timer(0.3), "timeout")
	$Camera2D.target = activeCharacter # TODO ------------------v
	activeCharacter.currentAP = min(activeCharacter.currentAP + 4, activeCharacter.actionPoints)
	UpdateTurnQue()
	
func _on_Move_btn_pressed():
	Action = MOVE
	highlightAreaBuffer = GetArea(activeCharacter.position, activeCharacter.currentAP, true, [], true, false, true)
	for tile in highlightAreaBuffer:
		$TileMap/TargetMap.set_cellv(tile, 1)
	highlightAreaBuffer.sort()


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
		highlightAreaBuffer = GetArea(activeCharacter.position, activeSkill.range, activeSkill.diagonal, [], activeSkill.selfTarget)
		for tile in highlightAreaBuffer:
			$TileMap/TargetMap.set_cellv(tile, 0)
		Action = ATTACK

func OnDamageTaken(target, damage):
	target.TakeDmg(damage)
	if target.stats.hp <= 0:
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












