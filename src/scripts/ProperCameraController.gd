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
@export var mouse_sensitivity: float = 0.002
@export var collision_mask: int = 1

var player: CharacterBody3D
var camera: Camera3D
var first_person_camera: Camera3D

# Camera configuration
var camera_configs = {
	CameraMode.OVER_THE_SHOULDER: {
		"distance": 2.5,
		"height": 1.5,
		"side_offset": 0.5,
		"look_offset": Vector3(0, 0.5, 0)
	},
	CameraMode.THIRD_PERSON_CLOSE: {
		"distance": 4.0,
		"height": 2.0,
		"side_offset": 0.0,
		"look_offset": Vector3(0, 0.5, 0)
	},
	CameraMode.THIRD_PERSON_MEDIUM: {
		"distance": 7.0,
		"height": 3.0,
		"side_offset": 0.0,
		"look_offset": Vector3(0, 0.5, 0)
	},
	CameraMode.THIRD_PERSON_FAR: {
		"distance": 12.0,
		"height": 4.0,
		"side_offset": 0.0,
		"look_offset": Vector3(0, 0.5, 0)
	}
}

# Camera rotation
var yaw: float = 0.0
var pitch: float = 0.0

# God mode position (independent of player)
var god_mode_position: Vector3 = Vector3.ZERO

func _ready():
	player = get_parent() as CharacterBody3D
	first_person_camera = player.get_node_or_null("Camera3D")
	
	# Create the main camera as a child
	camera = Camera3D.new()
	camera.name = "MainCamera"
	camera.fov = 75.0
	add_child(camera)
	
	# Make camera top-level so it can move independently
	camera.top_level = true
	
	print("ProperCameraController ready")
	update_camera_mode()

func _input(event):
	# Camera switching
	if event is InputEventKey and event.pressed:
		match event.keycode:
			49: set_camera_mode(CameraMode.FIRST_PERSON)
			50: set_camera_mode(CameraMode.OVER_THE_SHOULDER)
			51: set_camera_mode(CameraMode.THIRD_PERSON_CLOSE)
			52: set_camera_mode(CameraMode.THIRD_PERSON_MEDIUM)
			53: set_camera_mode(CameraMode.THIRD_PERSON_FAR)
			54: set_camera_mode(CameraMode.GOD_MODE)
	
	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		handle_mouse_look(event.relative)

func handle_mouse_look(mouse_delta: Vector2):
	var delta = mouse_delta * mouse_sensitivity
	
	if camera_mode == CameraMode.FIRST_PERSON:
		# First person rotates player and camera pitch
		player.rotate_y(-delta.x)
		first_person_camera.rotate_x(-delta.y)
		first_person_camera.rotation.x = clamp(first_person_camera.rotation.x, -PI/2, PI/2)
	elif camera_mode == CameraMode.GOD_MODE:
		# God mode free look
		yaw -= delta.x
		pitch -= delta.y
		pitch = clamp(pitch, -PI/2, PI/2)
	else:
		# Third person rotates camera around player
		yaw -= delta.x
		pitch -= delta.y
		pitch = clamp(pitch, -PI/3, PI/6)

func _physics_process(delta):
	if camera_mode == CameraMode.FIRST_PERSON:
		return  # First person camera is handled by the player
	
	if camera_mode == CameraMode.GOD_MODE:
		handle_god_mode(delta)
		return
	
	# Third person camera positioning
	var config = camera_configs.get(camera_mode, {
		"distance": 5.0,
		"height": 2.0,
		"side_offset": 0.0,
		"look_offset": Vector3(0, 0.5, 0)
	})
	
	var target_pos = player.global_position + config["look_offset"]
	
	# Calculate camera position based on yaw and pitch
	var camera_offset = Vector3(config["side_offset"], 0, config["distance"])
	camera_offset = camera_offset.rotated(Vector3.UP, yaw)
	
	var desired_pos = target_pos + camera_offset
	desired_pos.y = target_pos.y + config["height"]
	
	# Collision detection
	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(target_pos, desired_pos)
	query.collision_mask = collision_mask
	query.exclude = [player]
	
	var result = space_state.intersect_ray(query)
	if result:
		# Move camera closer if there's an obstacle
		var hit_pos = result.position
		var safe_distance = target_pos.distance_to(hit_pos) * 0.9
		var direction = (desired_pos - target_pos).normalized()
		desired_pos = target_pos + direction * safe_distance
	
	# Set camera position and look at target
	camera.global_position = desired_pos
	camera.look_at(target_pos, Vector3.UP)
	
	# Apply pitch rotation
	var transform = camera.transform
	transform.basis = Basis(transform.basis.x, pitch) * transform.basis
	camera.transform = transform
	
	# Debug: print("Camera at: ", camera.global_position, " looking at: ", target_pos)

func handle_god_mode(delta):
	var speed = 10.0
	if Input.is_action_pressed("sprint"):
		speed *= 2.0
	
	var input = Vector3()
	input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	input.y = Input.get_action_strength("jump") - Input.get_action_strength("move_down")
	
	# Transform input based on camera's current rotation
	var movement = camera.global_transform.basis * input
	god_mode_position += movement.normalized() * speed * delta
	
	# Apply position and rotation
	camera.global_position = god_mode_position
	camera.rotation = Vector3(pitch, yaw, 0)

func set_camera_mode(mode: CameraMode):
	camera_mode = mode
	update_camera_mode()

func update_camera_mode():
	print("\nSwitching to: ", get_mode_name())
	
	# Hide all cameras first
	if first_person_camera:
		first_person_camera.current = false
	camera.current = false
	
	# Show/hide player mesh
	var mesh = player.get_node_or_null("MeshInstance3D")
	
	match camera_mode:
		CameraMode.FIRST_PERSON:
			if first_person_camera:
				first_person_camera.current = true
			if mesh:
				mesh.visible = false
		_:
			camera.current = true
			if mesh:
				mesh.visible = true
			
			# Initialize camera rotation to match player direction
			if camera_mode == CameraMode.GOD_MODE:
				# Initialize god mode at current camera position
				god_mode_position = camera.global_position
			elif camera_mode != CameraMode.GOD_MODE:
				yaw = player.rotation.y

func get_mode_name() -> String:
	match camera_mode:
		CameraMode.FIRST_PERSON: return "First Person"
		CameraMode.OVER_THE_SHOULDER: return "Over The Shoulder"
		CameraMode.THIRD_PERSON_CLOSE: return "Third Person - Close"
		CameraMode.THIRD_PERSON_MEDIUM: return "Third Person - Medium"
		CameraMode.THIRD_PERSON_FAR: return "Third Person - Far"
		CameraMode.GOD_MODE: return "God Mode"
		_: return "Unknown"