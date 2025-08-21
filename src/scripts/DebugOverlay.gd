extends CanvasLayer

var fps_label: Label
var position_label: Label
var memory_label: Label
var time_scale_label: Label
var player_ref: Node3D

func _ready():
	create_debug_ui()
	visible = false

func create_debug_ui():
	var panel = PanelContainer.new()
	panel.modulate.a = 0.8
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)
	
	# FPS Display
	fps_label = Label.new()
	fps_label.add_theme_font_size_override("font_size", 14)
	fps_label.add_theme_color_override("font_color", Color.GREEN)
	vbox.add_child(fps_label)
	
	# Position Display
	position_label = Label.new()
	position_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(position_label)
	
	# Memory Usage
	memory_label = Label.new()
	memory_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(memory_label)
	
	# Time Scale
	time_scale_label = Label.new()
	time_scale_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(time_scale_label)
	
	# Debug Controls Info
	var controls_label = Label.new()
	controls_label.text = "`: Debug | ~: Console | N: Noclip | M: Scenes | P: Perf | R: Reset"
	controls_label.add_theme_font_size_override("font_size", 11)
	controls_label.add_theme_color_override("font_color", Color.GRAY)
	vbox.add_child(controls_label)

func _process(_delta):
	if not visible:
		return
		
	# Update FPS
	var fps = Engine.get_frames_per_second()
	fps_label.text = "FPS: %d" % fps
	fps_label.add_theme_color_override("font_color", 
		Color.GREEN if fps >= 55 else Color.YELLOW if fps >= 30 else Color.RED)
	
	# Update Position
	if player_ref:
		var pos = player_ref.global_position
		position_label.text = "Pos: %.1f, %.1f, %.1f" % [pos.x, pos.y, pos.z]
	
	# Update Memory
	var static_mem = OS.get_static_memory_usage() / 1048576.0
	memory_label.text = "Memory: %.1f MB" % static_mem
	
	# Update Time Scale
	time_scale_label.text = "Time Scale: %.2fx" % Engine.time_scale

func set_player_reference(player: Node3D):
	player_ref = player

func _input(event):
	if event.is_action_pressed("toggle_debug"):
		visible = !visible