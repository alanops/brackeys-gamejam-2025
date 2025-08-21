extends Node3D

# Camera controller that manages first and third person views

enum CameraMode {
	FIRST_PERSON,
	THIRD_PERSON_CLOSE,
	THIRD_PERSON_MEDIUM,
	THIRD_PERSON_FAR,
	THIRD_PERSON_TOP_DOWN
}

@export var camera_mode: CameraMode = CameraMode.FIRST_PERSON
@export var smooth_transition: bool = true
@export var transition_speed: float = 8.0
@export var mouse_sensitivity: float = 0.002

var player: CharacterBody3D
var first_person_camera: Camera3D
var third_person_camera: Camera3D
var camera_pivot: Node3D

# Third person camera settings
var third_person_distances = {
	CameraMode.THIRD_PERSON_CLOSE: 2.5,
	CameraMode.THIRD_PERSON_MEDIUM: 4.5,
	CameraMode.THIRD_PERSON_FAR: 7.0,
	CameraMode.THIRD_PERSON_TOP_DOWN: 6.0
}

var third_person_heights = {
	CameraMode.THIRD_PERSON_CLOSE: 1.5,
	CameraMode.THIRD_PERSON_MEDIUM: 2.0,
	CameraMode.THIRD_PERSON_FAR: 2.5,
	CameraMode.THIRD_PERSON_TOP_DOWN: 8.0
}

var third_person_angles = {
	CameraMode.THIRD_PERSON_CLOSE: -10.0,
	CameraMode.THIRD_PERSON_MEDIUM: -15.0,
	CameraMode.THIRD_PERSON_FAR: -20.0,
	CameraMode.THIRD_PERSON_TOP_DOWN: -70.0
}

var target_position: Vector3
var target_rotation: Vector3
var current_distance: float
var current_height: float
var current_angle: float

func _ready():
	player = get_parent() as CharacterBody3D
	first_person_camera = player.get_node("Camera3D")
	
	# Create third person camera setup
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	player.add_child(camera_pivot)
	camera_pivot.position = Vector3(0, 1.6, 0)  # Eye level
	
	third_person_camera = Camera3D.new()
	third_person_camera.name = "ThirdPersonCamera"
	third_person_camera.fov = 75.0
	camera_pivot.add_child(third_person_camera)
	
	# Initialize camera positions
	update_camera_mode()

func _input(event):
	if event.is_action_pressed("camera_first_person"):
		set_camera_mode(CameraMode.FIRST_PERSON)
	elif event.is_action_pressed("camera_third_close"):
		set_camera_mode(CameraMode.THIRD_PERSON_CLOSE)
	elif event.is_action_pressed("camera_third_medium"):
		set_camera_mode(CameraMode.THIRD_PERSON_MEDIUM)
	elif event.is_action_pressed("camera_third_far"):
		set_camera_mode(CameraMode.THIRD_PERSON_FAR)
	elif event.is_action_pressed("camera_top_down"):
		set_camera_mode(CameraMode.THIRD_PERSON_TOP_DOWN)
	
	# Handle mouse look for third person
	if camera_mode != CameraMode.FIRST_PERSON and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_delta = event.relative * mouse_sensitivity
		
		# Rotate the pivot horizontally (Y axis)
		camera_pivot.rotate_y(-mouse_delta.x)
		
		# Rotate the camera vertically, but clamp it
		var current_x_rot = third_person_camera.rotation.x
		var new_x_rot = current_x_rot + (-mouse_delta.y)
		new_x_rot = clamp(new_x_rot, deg_to_rad(-60), deg_to_rad(60))
		third_person_camera.rotation.x = new_x_rot

func _process(delta):
	if camera_mode != CameraMode.FIRST_PERSON:
		update_third_person_camera(delta)

func set_camera_mode(new_mode: CameraMode):
	camera_mode = new_mode
	update_camera_mode()

func update_camera_mode():
	match camera_mode:
		CameraMode.FIRST_PERSON:
			first_person_camera.current = true
			third_person_camera.current = false
			# Hide player mesh in first person if visible
			if player.has_node("MeshInstance3D"):
				player.get_node("MeshInstance3D").visible = false
		_:
			first_person_camera.current = false
			third_person_camera.current = true
			# Show player mesh in third person
			if player.has_node("MeshInstance3D"):
				player.get_node("MeshInstance3D").visible = true
			
			# Set target values for third person
			current_distance = third_person_distances.get(camera_mode, 4.0)
			current_height = third_person_heights.get(camera_mode, 2.0)
			current_angle = third_person_angles.get(camera_mode, -15.0)
			
			# Immediately set position if not smoothing
			if not smooth_transition:
				apply_third_person_position()

func update_third_person_camera(delta):
	if smooth_transition:
		# Smoothly interpolate to target position
		var target_pos = Vector3(0, 0, current_distance)
		target_pos.y = current_height
		
		third_person_camera.position = third_person_camera.position.lerp(target_pos, transition_speed * delta)
		
		# Smoothly interpolate rotation
		var target_rot = Vector3(deg_to_rad(current_angle), 0, 0)
		third_person_camera.rotation.x = lerp_angle(third_person_camera.rotation.x, target_rot.x, transition_speed * delta)
	else:
		apply_third_person_position()

func apply_third_person_position():
	third_person_camera.position = Vector3(0, current_height, current_distance)
	third_person_camera.rotation.x = deg_to_rad(current_angle)
	third_person_camera.rotation.y = 0
	third_person_camera.rotation.z = 0

func get_camera_mode_name() -> String:
	match camera_mode:
		CameraMode.FIRST_PERSON:
			return "First Person"
		CameraMode.THIRD_PERSON_CLOSE:
			return "Third Person - Close"
		CameraMode.THIRD_PERSON_MEDIUM:
			return "Third Person - Medium"
		CameraMode.THIRD_PERSON_FAR:
			return "Third Person - Far"
		CameraMode.THIRD_PERSON_TOP_DOWN:
			return "Top Down"
		_:
			return "Unknown"