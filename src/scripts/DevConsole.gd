extends CanvasLayer

signal command_executed(command: String, args: Array)

var console_panel: PanelContainer
var output_text: RichTextLabel
var input_field: LineEdit
var command_history: Array[String] = []
var history_index: int = -1

var commands = {
	"help": "Show available commands",
	"clear": "Clear console output",
	"quit": "Quit to main menu",
	"restart": "Restart current scene",
	"scene": "Load scene (usage: scene [path])",
	"timescale": "Set time scale (usage: timescale [0.1-5.0])",
	"teleport": "Teleport player (usage: teleport x y z)",
	"spawn": "Spawn object at player (usage: spawn [object_name])",
	"godmode": "Toggle invincibility",
	"noclip": "Toggle noclip mode",
	"fps_limit": "Set FPS limit (usage: fps_limit [30/60/120/0])",
	"screenshot": "Take screenshot",
	"give": "Give item/resource (usage: give [item] [amount])"
}

func _ready():
	create_console_ui()
	visible = false

func create_console_ui():
	# Background panel
	console_panel = PanelContainer.new()
	console_panel.custom_minimum_size = Vector2(800, 400)
	console_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	console_panel.position = Vector2(10, 10)
	console_panel.modulate.a = 0.95
	add_child(console_panel)
	
	var vbox = VBoxContainer.new()
	console_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Developer Console"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	# Output area
	output_text = RichTextLabel.new()
	output_text.custom_minimum_size = Vector2(780, 320)
	output_text.bbcode_enabled = true
	output_text.scroll_following = true
	vbox.add_child(output_text)
	
	# Input field
	input_field = LineEdit.new()
	input_field.placeholder_text = "Enter command..."
	input_field.text_submitted.connect(_on_command_entered)
	vbox.add_child(input_field)
	
	# Initial message
	write_line("[color=green]Developer Console v1.0[/color]")
	write_line("Type 'help' for available commands")

func _input(event):
	if event.is_action_pressed("ui_home"): # F4 key
		toggle_console()
	
	if visible:
		if event.is_action_pressed("ui_up"):
			navigate_history(-1)
		elif event.is_action_pressed("ui_down"):
			navigate_history(1)

func toggle_console():
	visible = !visible
	if visible:
		input_field.grab_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func navigate_history(direction: int):
	if command_history.is_empty():
		return
	
	history_index = clamp(history_index + direction, -1, command_history.size() - 1)
	if history_index >= 0:
		input_field.text = command_history[history_index]
	else:
		input_field.text = ""

func _on_command_entered(text: String):
	if text.strip_edges() == "":
		return
	
	command_history.append(text)
	history_index = command_history.size()
	
	write_line("[color=cyan]> " + text + "[/color]")
	execute_command(text)
	input_field.clear()

func execute_command(text: String):
	var parts = text.strip_edges().split(" ")
	if parts.is_empty():
		return
	
	var cmd = parts[0].to_lower()
	var args = parts.slice(1)
	
	match cmd:
		"help":
			show_help()
		"clear":
			output_text.clear()
		"quit":
			get_tree().change_scene_to_file("res://src/scenes/Main.tscn")
		"restart":
			get_tree().reload_current_scene()
		"scene":
			if args.size() > 0:
				load_scene(args[0])
			else:
				write_line("[color=red]Usage: scene [path][/color]")
		"timescale":
			if args.size() > 0:
				set_timescale(args[0].to_float())
			else:
				write_line("[color=red]Usage: timescale [0.1-5.0][/color]")
		"teleport":
			if args.size() >= 3:
				teleport_player(args[0].to_float(), args[1].to_float(), args[2].to_float())
			else:
				write_line("[color=red]Usage: teleport x y z[/color]")
		"noclip":
			toggle_noclip()
		"fps_limit":
			if args.size() > 0:
				set_fps_limit(args[0].to_int())
			else:
				write_line("[color=red]Usage: fps_limit [30/60/120/0][/color]")
		"screenshot":
			take_screenshot()
		_:
			write_line("[color=red]Unknown command: " + cmd + "[/color]")
	
	command_executed.emit(cmd, args)

func show_help():
	write_line("[color=yellow]Available Commands:[/color]")
	for cmd in commands:
		write_line("  [color=white]%s[/color] - %s" % [cmd, commands[cmd]])

func load_scene(path: String):
	if not path.begins_with("res://"):
		path = "res://src/scenes/" + path + ".tscn"
	
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
		write_line("[color=green]Loading scene: " + path + "[/color]")
	else:
		write_line("[color=red]Scene not found: " + path + "[/color]")

func set_timescale(scale: float):
	scale = clamp(scale, 0.1, 5.0)
	Engine.time_scale = scale
	write_line("[color=green]Time scale set to: %.2fx[/color]" % scale)

func teleport_player(x: float, y: float, z: float):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector3(x, y, z)
		write_line("[color=green]Teleported to: %.1f, %.1f, %.1f[/color]" % [x, y, z])
	else:
		write_line("[color=red]No player found in scene[/color]")

func toggle_noclip():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("toggle_noclip"):
		player.toggle_noclip()
		write_line("[color=green]Noclip toggled[/color]")
	else:
		write_line("[color=red]Noclip not available[/color]")

func set_fps_limit(limit: int):
	Engine.max_fps = limit
	if limit == 0:
		write_line("[color=green]FPS limit removed[/color]")
	else:
		write_line("[color=green]FPS limit set to: %d[/color]" % limit)

func take_screenshot():
	var datetime = Time.get_datetime_dict_from_system()
	var filename = "screenshot_%04d%02d%02d_%02d%02d%02d.png" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	var path = "user://screenshots/" + filename
	
	DirAccess.make_dir_absolute("user://screenshots")
	get_viewport().get_texture().get_image().save_png(path)
	write_line("[color=green]Screenshot saved: " + filename + "[/color]")

func write_line(text: String):
	output_text.append_text(text + "\n")