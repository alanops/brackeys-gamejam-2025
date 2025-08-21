extends CanvasLayer

var fps_label: Label
var frame_time_label: Label
var gpu_time_label: Label
var draw_calls_label: Label
var memory_label: Label
var panel: PanelContainer

var frame_times: Array[float] = []
var max_samples = 60

func _ready():
	create_performance_ui()
	
func create_performance_ui():
	# Panel container
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-220, 10)
	panel.custom_minimum_size = Vector2(200, 0)
	panel.modulate.a = 0.85
	add_child(panel)
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.3, 0.3, 0.4, 0.8)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Performance"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Separator
	var separator = HSeparator.new()
	separator.add_theme_color_override("separator", Color(0.4, 0.4, 0.5))
	vbox.add_child(separator)
	
	# FPS
	fps_label = Label.new()
	fps_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(fps_label)
	
	# Frame Time
	frame_time_label = Label.new()
	frame_time_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(frame_time_label)
	
	# GPU Time
	gpu_time_label = Label.new()
	gpu_time_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(gpu_time_label)
	
	# Draw Calls
	draw_calls_label = Label.new()
	draw_calls_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(draw_calls_label)
	
	# Memory
	memory_label = Label.new()
	memory_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(memory_label)

func _process(delta):
	update_performance_metrics(delta)

func update_performance_metrics(delta):
	# Track frame times
	frame_times.append(delta * 1000.0)  # Convert to milliseconds
	if frame_times.size() > max_samples:
		frame_times.pop_front()
	
	# Calculate average frame time
	var avg_frame_time = 0.0
	for ft in frame_times:
		avg_frame_time += ft
	avg_frame_time /= frame_times.size()
	
	# FPS
	var fps = Engine.get_frames_per_second()
	var fps_color = Color.GREEN
	if fps < 30:
		fps_color = Color.RED
	elif fps < 60:
		fps_color = Color.YELLOW
	
	fps_label.text = "FPS: %d" % fps
	fps_label.add_theme_color_override("font_color", fps_color)
	
	# Frame Time (CPU)
	var frame_time_color = Color.CYAN
	if avg_frame_time > 33.33:  # > 30 FPS threshold
		frame_time_color = Color.ORANGE
	if avg_frame_time > 16.67:  # > 60 FPS threshold
		frame_time_color = Color.RED
		
	frame_time_label.text = "CPU: %.1f ms" % avg_frame_time
	frame_time_label.add_theme_color_override("font_color", frame_time_color)
	
	# GPU Time (using Performance monitor)
	var gpu_time_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	gpu_time_label.text = "GPU: %.1f ms" % gpu_time_ms
	gpu_time_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	
	# Draw Calls
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var draw_color = Color.WHITE
	if draw_calls > 1000:
		draw_color = Color.ORANGE
	if draw_calls > 2000:
		draw_color = Color.RED
		
	draw_calls_label.text = "Draw: %d" % draw_calls
	draw_calls_label.add_theme_color_override("font_color", draw_color)
	
	# Memory
	var memory_mb = OS.get_static_memory_usage() / (1024.0 * 1024.0)
	var mem_color = Color.WHITE
	if memory_mb > 100:
		mem_color = Color.YELLOW
	if memory_mb > 200:
		mem_color = Color.ORANGE
		
	memory_label.text = "RAM: %.0f MB" % memory_mb
	memory_label.add_theme_color_override("font_color", mem_color)

func _input(event):
	if event.is_action_pressed("toggle_performance"):
		visible = !visible