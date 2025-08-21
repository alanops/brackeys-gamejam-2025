extends CanvasLayer

var camera_controller: Node3D
var mode_label: Label
var help_label: Label

func _ready():
	create_overlay_ui()
	
func create_overlay_ui():
	# Camera mode display
	var panel = PanelContainer.new()
	panel.modulate.a = 0.7
	panel.position = Vector2(20, 20)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Current mode label
	mode_label = Label.new()
	mode_label.add_theme_font_size_override("font_size", 14)
	mode_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(mode_label)
	
	# Help text
	help_label = Label.new()
	help_label.text = "1: First Person | 2: Over Shoulder | 3: Third Close\n4: Third Medium | 5: God Mode (Free Cam)"
	help_label.add_theme_font_size_override("font_size", 11)
	help_label.add_theme_color_override("font_color", Color.GRAY)
	vbox.add_child(help_label)

func _process(_delta):
	if camera_controller:
		mode_label.text = "Camera: " + camera_controller.get_camera_mode_name()

func set_camera_controller(controller: Node3D):
	camera_controller = controller