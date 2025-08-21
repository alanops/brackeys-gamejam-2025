extends CanvasLayer

var player_ref: CharacterBody3D
var panel: PanelContainer
var sliders: Dictionary = {}

# Movement parameter definitions
var movement_params = {
	"walk_speed": {"min": 2.0, "max": 10.0, "step": 0.1, "default": 5.0},
	"sprint_speed": {"min": 5.0, "max": 15.0, "step": 0.1, "default": 8.5},
	"jump_velocity": {"min": 3.0, "max": 10.0, "step": 0.1, "default": 6.0},
	"acceleration": {"min": 5.0, "max": 20.0, "step": 0.5, "default": 10.0},
	"friction": {"min": 5.0, "max": 20.0, "step": 0.5, "default": 12.0},
	"air_acceleration": {"min": 0.5, "max": 5.0, "step": 0.1, "default": 2.0},
	"air_friction": {"min": 0.5, "max": 3.0, "step": 0.1, "default": 1.0},
	"step_up_velocity": {"min": 1.0, "max": 6.0, "step": 0.1, "default": 3.0},
	"max_step_height": {"min": 0.2, "max": 1.0, "step": 0.1, "default": 0.5},
	"mouse_sensitivity": {"min": 0.0005, "max": 0.005, "step": 0.0001, "default": 0.002},
}

func _ready():
	create_tuner_ui()
	visible = false

func create_tuner_ui():
	panel = PanelContainer.new()
	panel.modulate.a = 0.9
	panel.position = Vector2(20, 100)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Movement Tuner (T to toggle)"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)
	
	# Create sliders for each parameter
	for param_name in movement_params:
		var param_data = movement_params[param_name]
		create_parameter_slider(vbox, param_name, param_data)
	
	# Reset button
	var reset_btn = Button.new()
	reset_btn.text = "Reset to Defaults"
	reset_btn.pressed.connect(_on_reset_pressed)
	vbox.add_child(reset_btn)
	
	# Save/Load buttons
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	var save_btn = Button.new()
	save_btn.text = "Save Preset"
	save_btn.pressed.connect(_on_save_preset)
	hbox.add_child(save_btn)
	
	var load_btn = Button.new()
	load_btn.text = "Load Preset"
	load_btn.pressed.connect(_on_load_preset)
	hbox.add_child(load_btn)

func create_parameter_slider(parent: VBoxContainer, param_name: String, param_data: Dictionary):
	var container = VBoxContainer.new()
	parent.add_child(container)
	
	# Parameter label
	var label = Label.new()
	label.text = param_name.capitalize().replace("_", " ") + ": %.3f" % param_data.default
	label.add_theme_font_size_override("font_size", 12)
	container.add_child(label)
	
	# Slider
	var slider = HSlider.new()
	slider.min_value = param_data.min
	slider.max_value = param_data.max
	slider.step = param_data.step
	slider.value = param_data.default
	slider.custom_minimum_size.x = 200
	container.add_child(slider)
	
	# Connect slider to update function
	slider.value_changed.connect(_on_parameter_changed.bind(param_name, label))
	
	# Store references
	sliders[param_name] = {"slider": slider, "label": label}

func _on_parameter_changed(param_name: String, label: Label, value: float):
	# Update label
	label.text = param_name.capitalize().replace("_", " ") + ": %.3f" % value
	
	# Update player parameter if reference exists
	if player_ref and player_ref.has_method("set_movement_parameter"):
		player_ref.set_movement_parameter(param_name, value)
		print("Updated %s to %.3f" % [param_name, value])  # Debug output
	else:
		print("No player reference for parameter update: %s" % param_name)

func _on_reset_pressed():
	for param_name in movement_params:
		var default_value = movement_params[param_name].default
		var slider_data = sliders[param_name]
		slider_data.slider.value = default_value
		# This will trigger the value_changed signal and update everything

func _on_save_preset():
	var preset_data = {}
	for param_name in sliders:
		preset_data[param_name] = sliders[param_name].slider.value
	
	var file = FileAccess.open("user://movement_preset.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(preset_data))
		file.close()
		print("Movement preset saved!")

func _on_load_preset():
	var file = FileAccess.open("user://movement_preset.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var result = json.parse(json_string)
		if result == OK:
			var preset_data = json.data
			for param_name in preset_data:
				if sliders.has(param_name):
					sliders[param_name].slider.value = preset_data[param_name]
			print("Movement preset loaded!")
		else:
			print("Failed to parse preset file")
	else:
		print("No preset file found")

func set_player_reference(player: CharacterBody3D):
	player_ref = player
	print("Movement tuner connected to player: ", player.name if player else "null")

func _input(event):
	if event.is_action_pressed("toggle_movement_tuner"):
		visible = !visible