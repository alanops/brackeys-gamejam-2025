extends Control

var scene_list = {
	"Main Menu": "res://src/scenes/Main.tscn",
	"Dungeon Room": "res://src/scenes/DungeonRoomEnhanced.tscn",
	"Test Scene": "res://src/scenes/TestScene.tscn"
}

var panel: PanelContainer
var scene_buttons: VBoxContainer

func _ready():
	create_ui()
	visible = false

func create_ui():
	# Create panel
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 300)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-210, 10)
	panel.modulate.a = 0.9
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Scene Switcher"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Scene buttons
	scene_buttons = VBoxContainer.new()
	vbox.add_child(scene_buttons)
	
	for scene_name in scene_list:
		var btn = Button.new()
		btn.text = scene_name
		btn.pressed.connect(func(): load_scene(scene_list[scene_name]))
		scene_buttons.add_child(btn)
	
	# Add scene button
	vbox.add_child(HSeparator.new())
	var add_btn = Button.new()
	add_btn.text = "+ Add Current Scene"
	add_btn.pressed.connect(add_current_scene)
	vbox.add_child(add_btn)

func _input(event):
	if event.is_action_pressed("toggle_scene_switcher"):
		visible = !visible
		if visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func load_scene(path: String):
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		print("Scene not found: " + path)

func add_current_scene():
	var current_scene = get_tree().current_scene.scene_file_path
	var scene_name = current_scene.get_file().get_basename()
	
	if not scene_list.has(scene_name):
		scene_list[scene_name] = current_scene
		
		var btn = Button.new()
		btn.text = scene_name
		btn.pressed.connect(func(): load_scene(current_scene))
		scene_buttons.add_child(btn)