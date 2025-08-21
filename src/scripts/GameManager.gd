extends Node

# Singleton for managing game-wide systems and dev tools

var debug_overlay_scene = preload("res://src/scenes/DebugOverlay.tscn")
var dev_console_scene = preload("res://src/scenes/DevConsole.tscn")
var scene_switcher_scene = preload("res://src/scenes/SceneSwitcher.tscn")
var performance_overlay_scene = preload("res://src/scenes/PerformanceOverlay.tscn")
var movement_tuner_script = preload("res://src/scripts/MovementTuner.gd")

var debug_overlay: CanvasLayer
var dev_console: CanvasLayer
var scene_switcher: Control
var performance_overlay: CanvasLayer
var movement_tuner: CanvasLayer

func _ready():
	# Make this a singleton
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Initialize dev tools
	setup_debug_overlay()
	setup_dev_console()
	setup_scene_switcher()
	setup_performance_overlay()
	setup_movement_tuner()
	
	# Register custom project settings
	register_debug_settings()

func setup_debug_overlay():
	debug_overlay = debug_overlay_scene.instantiate()
	add_child(debug_overlay)

func setup_dev_console():
	dev_console = dev_console_scene.instantiate()
	add_child(dev_console)
	
	# Connect to console commands
	dev_console.command_executed.connect(_on_console_command)

func setup_scene_switcher():
	scene_switcher = scene_switcher_scene.instantiate()
	add_child(scene_switcher)

func setup_performance_overlay():
	performance_overlay = performance_overlay_scene.instantiate()
	add_child(performance_overlay)

func setup_movement_tuner():
	movement_tuner = CanvasLayer.new()
	movement_tuner.set_script(movement_tuner_script)
	add_child(movement_tuner)

func _on_console_command(command: String, args: Array):
	# Handle global commands here
	match command:
		"godmode":
			toggle_godmode()
		"give":
			if args.size() >= 2:
				give_item(args[0], args[1].to_int())

func toggle_godmode():
	# Implement godmode logic when health system exists
	print("Godmode toggled")

func give_item(item: String, amount: int):
	# Implement inventory system integration
	print("Gave %d x %s" % [amount, item])

func register_debug_settings():
	# Add custom project settings for debug features
	if not ProjectSettings.has_setting("debug/show_fps_on_start"):
		ProjectSettings.set_setting("debug/show_fps_on_start", false)
	if not ProjectSettings.has_setting("debug/enable_dev_console"):
		ProjectSettings.set_setting("debug/enable_dev_console", true)

# Global helper functions
func take_screenshot():
	var datetime = Time.get_datetime_dict_from_system()
	var filename = "screenshot_%04d%02d%02d_%02d%02d%02d.png" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	var path = "user://screenshots/" + filename
	
	DirAccess.make_dir_absolute("user://screenshots")
	get_viewport().get_texture().get_image().save_png(path)
	print("Screenshot saved: " + filename)
	
	# Show notification
	if debug_overlay and debug_overlay.has_method("show_notification"):
		debug_overlay.show_notification("Screenshot saved!")