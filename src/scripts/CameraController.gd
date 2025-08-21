extends Node3D

enum CameraMode {
	FIRST_PERSON,
	OVER_THE_SHOULDER,
	THIRD_PERSON_CLOSE,
	THIRD_PERSON_MEDIUM,
	THIRD_PERSON_FAR,
	GOD_MODE
}

@export var camera_mode: CameraMode = CameraMode.FIRST_PERSON
@export var transition_speed: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var collision_mask: int = 1

var player: CharacterBody3D
var first_person_camera: Camera3D
var spring_arm: SpringArm3D
var third_person_camera: Camera3D
var god_mode_camera: Camera3D

# Camera configuration per mode
var camera_configs = {
	CameraMode.OVER_THE_SHOULDER: {
		"spring_length": 2.0,
		"position": Vector3(0.6, 1.6, 0),
		"rotation": Vector3(0, 0, 0)
	},
	CameraMode.THIRD_PERSON_CLOSE: {
		"spring_length": 4.0,
		"position": Vector3(0, 1.8, 0),
		"rotation": Vector3(-0.2, 0, 0)
	},
	CameraMode.THIRD_PERSON_MEDIUM: {
		"spring_length": 7.0,
		"position": Vector3(0, 2.2, 0),
		"rotation": Vector3(-0.3, 0, 0)
	},
	CameraMode.THIRD_PERSON_FAR: {
		"spring_length": 12.0,
		"position": Vector3(0, 3.0, 0),
		"rotation": Vector3(-0.4, 0, 0)
	}
}

func _ready():
	player = get_parent() as CharacterBody3D
	first_person_camera = player.get_node("Camera3D")
	
	print("\nCameraController _ready()")
	print("Player: ", player)
	print("First person camera: ", first_person_camera)
	
	# Create SpringArm3D for third person cameras
	spring_arm = SpringArm3D.new()
	spring_arm.name = "SpringArm3D"
	spring_arm.collision_mask = collision_mask
	spring_arm.spring_length = 5.0
	spring_arm.margin = 0.2
	# Important: SpringArm3D needs to face backward for third person
	spring_arm.rotation = Vector3(0, PI, 0)  # Rotate 180 degrees
	player.add_child(spring_arm)
	
	# Create third person camera attached to spring arm
	third_person_camera = Camera3D.new()
	third_person_camera.name = "ThirdPersonCamera"
	third_person_camera.fov = 75.0
	third_person_camera.position = Vector3(0, 0, 0)  # Camera at the end of the arm
	spring_arm.add_child(third_person_camera)
	
	# Create god mode camera
	god_mode_camera = Camera3D.new()
	god_mode_camera.name = "GodModeCamera"
	god_mode_camera.fov = 75.0
	player.add_child(god_mode_camera)
	god_mode_camera.position = Vector3(0, 5, 5)
	
	# Initialize camera
	print("Camera setup complete. SpringArm: ", spring_arm, " ThirdPersonCam: ", third_person_camera)
	update_camera_mode()

func _input(event):
	# Camera switching with number keys
	if event is InputEventKey and event.pressed:
		match event.keycode:
			49:  # Key 1
				set_camera_mode(CameraMode.FIRST_PERSON)
			50:  # Key 2
				set_camera_mode(CameraMode.OVER_THE_SHOULDER)
			51:  # Key 3
				set_camera_mode(CameraMode.THIRD_PERSON_CLOSE)
			52:  # Key 4
				set_camera_mode(CameraMode.THIRD_PERSON_MEDIUM)
			53:  # Key 5
				set_camera_mode(CameraMode.THIRD_PERSON_FAR)
			54:  # Key 6
				set_camera_mode(CameraMode.GOD_MODE)
	
	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		handle_mouse_look(event.relative)

func handle_mouse_look(mouse_delta: Vector2):
	var delta = mouse_delta * mouse_sensitivity
	
	match camera_mode:
		CameraMode.FIRST_PERSON:
			# First person rotates player body and camera pitch
			player.rotate_y(-delta.x)
			first_person_camera.rotate_x(-delta.y)
			first_person_camera.rotation.x = clamp(first_person_camera.rotation.x, -PI/2, PI/2)
			
		CameraMode.GOD_MODE:
			# God mode rotates camera freely
			god_mode_camera.rotate_y(-delta.x)
			god_mode_camera.rotate_object_local(Vector3(1, 0, 0), -delta.y)
			var euler = god_mode_camera.rotation
			euler.x = clamp(euler.x, -PI/2, PI/2)
			god_mode_camera.rotation = euler
			
		_:
			# Third person modes rotate the spring arm
			spring_arm.rotate_y(-delta.x)
			spring_arm.rotation.x -= delta.y
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/3, PI/4)

func _process(delta):
	match camera_mode:
		CameraMode.GOD_MODE:
			update_god_mode_camera(delta)
		_:
			# SpringArm3D handles collision automatically for third person modes
			pass

func set_camera_mode(new_mode: CameraMode):
	camera_mode = new_mode
	update_camera_mode()

func update_camera_mode():
	print("\nSwitching to: ", get_camera_mode_name())
	
	# Disable all cameras first
	first_person_camera.current = false
	third_person_camera.current = false
	god_mode_camera.current = false
	
	# Configure based on mode
	match camera_mode:
		CameraMode.FIRST_PERSON:
			first_person_camera.current = true
			spring_arm.visible = false
			if player.has_node("MeshInstance3D"):
				player.get_node("MeshInstance3D").visible = false
				
		CameraMode.GOD_MODE:
			god_mode_camera.current = true
			spring_arm.visible = false
			if player.has_node("MeshInstance3D"):
				player.get_node("MeshInstance3D").visible = true
				
		_:
			# All third person modes
			third_person_camera.current = true
			spring_arm.visible = true
			if player.has_node("MeshInstance3D"):
				player.get_node("MeshInstance3D").visible = true
			
			# Apply configuration for specific third person mode
			var config = camera_configs.get(camera_mode, {})
			if config:
				spring_arm.spring_length = config.get("spring_length", 5.0)
				spring_arm.position = config.get("position", Vector3(0, 1.6, 0))
				var rot = config.get("rotation", Vector3.ZERO)
				spring_arm.rotation = rot
				
				# SpringArm3D automatically positions the camera, just ensure it's at origin
				third_person_camera.position = Vector3(0, 0, 0)
				
				print("SpringArm config - Length: ", spring_arm.spring_length, 
					  " Position: ", spring_arm.position,
					  " Camera local pos: ", third_person_camera.position,
					  " Camera global pos: ", third_person_camera.global_position)

func update_god_mode_camera(delta):
	var speed = 10.0
	if Input.is_action_pressed("sprint"):
		speed *= 2.0
	
	# Get movement input
	var input_dir = Vector3()
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	input_dir.y = Input.get_action_strength("jump") - Input.get_action_strength("move_down")
	
	# Transform movement relative to camera orientation
	var movement = god_mode_camera.global_transform.basis * input_dir
	god_mode_camera.global_position += movement.normalized() * speed * delta

func get_camera_mode_name() -> String:
	match camera_mode:
		CameraMode.FIRST_PERSON:
			return "First Person"
		CameraMode.OVER_THE_SHOULDER:
			return "Over The Shoulder"
		CameraMode.THIRD_PERSON_CLOSE:
			return "Third Person - Close"
		CameraMode.THIRD_PERSON_MEDIUM:
			return "Third Person - Medium"
		CameraMode.THIRD_PERSON_FAR:
			return "Third Person - Far"
		CameraMode.GOD_MODE:
			return "God Mode (Free Cam)"
		_:
			return "Unknown"
