extends CanvasLayer

# Game Development Center - Youtube
# https://www.youtube.com/watch?v=58PHsZI_KOo

onready var shortcutsPath = "ActionBar/TextureRect/HBoxContainer/"
var hotbar = {}
var selectedSpell = null

func _ready():
	for shortcut in get_tree().get_nodes_in_group("Shortcuts"):
		shortcut.connect("pressed" ,self , "SelectShortcut", [shortcut.get_parent().get_name()])
	var size = $ActionBar/TextureRect/HBoxContainer.get_child_count()
	for i in range(size):
		var name = $ActionBar/TextureRect/HBoxContainer.get_child(i).name
		hotbar[name] = null
		
func LoadShortcuts(learnedSkills):
	var i = 1
	get_node(shortcutsPath + "Shortcut" + str(1) + "/TextureButton/TextureProgress").value = 0
	for skill in learnedSkills:
		var skillIcon = load("res://res/textures/icons/skill_icons/" + skill.name + ".png")
		get_node(shortcutsPath + "Shortcut" + str(i) + "/TextureButton").set_normal_texture(skillIcon)
		hotbar["Shortcut" + str(i)] = skill
		i += 1
		
func SelectShortcut(shortcut):
	if hotbar[shortcut].currentCooldown == 0:
		selectedSpell = hotbar[shortcut]
		get_parent().SelectSpell(selectedSpell)

func _unhandled_input(event):
	if event is InputEventKey:
		if event.scancode == KEY_1 and event.is_pressed():
			SelectShortcut("Shortcut1")
		elif event.scancode == KEY_2 and event.is_pressed():
			SelectShortcut("Shortcut2")
		elif event.scancode == KEY_3 and event.is_pressed():
			SelectShortcut("Shortcut3")
		elif event.scancode == KEY_4 and event.is_pressed():
			SelectShortcut("Shortcut4")
		elif event.scancode == KEY_5 and event.is_pressed():
			SelectShortcut("Shortcut5")
		elif event.scancode == KEY_6 and event.is_pressed():
			SelectShortcut("Shortcut6")
		elif event.scancode == KEY_7 and event.is_pressed():
			SelectShortcut("Shortcut7")
		elif event.scancode == KEY_8 and event.is_pressed():
			SelectShortcut("Shortcut8")

func UpdateHotbarCooldown():
	#get_node(shortcutsPath + "Shortcut" + str(1) + "/TextureButton/TextureProgress").value = float(skill.currentCooldown / skill.spellCooldown) * 100
	for shortcut in get_tree().get_nodes_in_group("Shortcuts"):
		var skill = hotbar[shortcut.get_parent().name]
		if skill != null:
			shortcut.get_child(0).value = float(skill.currentCooldown / skill.spellCooldown) * 100
		









