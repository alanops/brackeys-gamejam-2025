extends Node3D

# Camera controller that manages first and third person views

enum CameraMode {
	FIRST_PERSON,
	OVER_THE_SHOULDER,
	THIRD_PERSON_CLOSE,
	THIRD_PERSON_MEDIUM,
	THIRD_PERSON_FAR,
	GOD_MODE
}

@export var camera_mode: CameraMode = CameraMode.FIRST_PERSON
@export var smooth_transition: bool = true
@export var position_smoothing: float = 5.0
@export var rotation_smoothing: float = 8.0
@export var mouse_sensitivity: float = 0.002
@export var collision_check: bool = true
@export var collision_offset: float = 0.3
@export var auto_rotate_speed: float = 2.0
@export var instant_switch: bool = true  # Instant jump on camera mode change

var player: CharacterBody3D
var first_person_camera: Camera3D
var third_person_camera: Camera3D
var god_mode_camera: Camera3D
var camera_pivot: Node3D
var camera_arm: Node3D

# Camera tracking and collision
var desired_position: Vector3
var desired_rotation: Vector3
var actual_position: Vector3
var actual_rotation: Vector3
var collision_mask: int = 1
var camera_velocity: Vector3
var last_player_velocity: Vector3
var velocity_smoothing: float = 0.1

# Auto-rotation when idle
var idle_timer: float = 0.0
var idle_threshold: float = 3.0
var auto_rotate_enabled: bool = true

# Third person camera settings with improved tracking
var third_person_distances = {
	CameraMode.OVER_THE_SHOULDER: 1.5,
	CameraMode.THIRD_PERSON_CLOSE: 4.0,
	CameraMode.THIRD_PERSON_MEDIUM: 7.0,
	CameraMode.THIRD_PERSON_FAR: 12.0,
	CameraMode.GOD_MODE: 0.0  # Not used in god mode
}

var third_person_heights = {
	CameraMode.OVER_THE_SHOULDER: 0.3,
	CameraMode.THIRD_PERSON_CLOSE: 1.0,
	CameraMode.THIRD_PERSON_MEDIUM: 2.0,
	CameraMode.THIRD_PERSON_FAR: 3.5,
	CameraMode.GOD_MODE: 0.0  # Not used in god mode
}

var third_person_angles = {
	CameraMode.OVER_THE_SHOULDER: 0.0,
	CameraMode.THIRD_PERSON_CLOSE: -10.0,
	CameraMode.THIRD_PERSON_MEDIUM: -15.0,
	CameraMode.THIRD_PERSON_FAR: -25.0,
	CameraMode.GOD_MODE: 0.0  # Not used in god mode
}

# Camera behavior settings per mode
var tracking_settings = {
	CameraMode.OVER_THE_SHOULDER: {"speed": 18.0, "offset": Vector3(0.8, 0, 0)},
	CameraMode.THIRD_PERSON_CLOSE: {"speed": 15.0, "offset": Vector3(0, 0, 0)},
	CameraMode.THIRD_PERSON_MEDIUM: {"speed": 12.0, "offset": Vector3(0, 0, 0)},
	CameraMode.THIRD_PERSON_FAR: {"speed": 10.0, "offset": Vector3(0, 0, 0)},
	CameraMode.GOD_MODE: {"speed": 20.0, "offset": Vector3(0, 0, 0)}
}

var target_position: Vector3
var target_rotation: Vector3
var current_distance: float
var current_height: float
var current_angle: float

func _ready():
	player = get_parent() as CharacterBody3D
	first_person_camera = player.get_node("Camera3D")
	
	# Create enhanced third person camera setup
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	player.add_child(camera_pivot)
	camera_pivot.position = Vector3(0, 1.6, 0)  # Eye level
	
	# Create camera arm for smooth positioning
	camera_arm = Node3D.new()
	camera_arm.name = "CameraArm"
	camera_pivot.add_child(camera_arm)
	
	third_person_camera = Camera3D.new()
	third_person_camera.name = "ThirdPersonCamera"
	third_person_camera.fov = 75.0
	camera_arm.add_child(third_person_camera)
	
	# Create god mode camera
	god_mode_camera = Camera3D.new()
	god_mode_camera.name = "GodModeCamera"
	god_mode_camera.fov = 75.0
	player.add_child(god_mode_camera)
	god_mode_camera.position = Vector3(0, 5, 5)
	
	# Initialize camera positions
	update_camera_mode()
	
	# Store initial player velocity
	last_player_velocity = player.velocity if player.velocity else Vector3.ZERO

func _input(event):
	if event.is_action_pressed("camera_first_person"):
		set_camera_mode(CameraMode.FIRST_PERSON)
	elif event.is_action_pressed("camera_third_close"):
		set_camera_mode(CameraMode.OVER_THE_SHOULDER)
	elif event.is_action_pressed("camera_third_medium"):
		set_camera_mode(CameraMode.THIRD_PERSON_CLOSE)
	elif event.is_action_pressed("camera_third_far"):
		set_camera_mode(CameraMode.THIRD_PERSON_MEDIUM)
	elif event.is_action_pressed("camera_top_down"):
		set_camera_mode(CameraMode.GOD_MODE)
	
	# Handle mouse look for different camera modes
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_delta = event.relative * mouse_sensitivity
		
		if camera_mode == CameraMode.GOD_MODE:
			# God mode: rotate camera directly
			god_mode_camera.rotate_y(-mouse_delta.x)
			god_mode_camera.rotate_object_local(Vector3(1, 0, 0), -mouse_delta.y)
			# Clamp pitch for god mode
			var euler = god_mode_camera.rotation
			euler.x = clamp(euler.x, -PI/2, PI/2)
			god_mode_camera.rotation = euler
		elif camera_mode != CameraMode.FIRST_PERSON:
			# Third person modes
			# Reset idle timer on mouse movement
			idle_timer = 0.0
			
			# Rotate the pivot horizontally (Y axis)
			camera_pivot.rotate_y(-mouse_delta.x)
			
			# Rotate the camera vertically with better limits per mode
			var pitch_limit = 60.0
			
			var current_x_rot = camera_arm.rotation.x
			var new_x_rot = current_x_rot + (-mouse_delta.y)
			new_x_rot = clamp(new_x_rot, deg_to_rad(-pitch_limit), deg_to_rad(pitch_limit))
			camera_arm.rotation.x = new_x_rot

func _process(delta):
	if camera_mode == CameraMode.GOD_MODE:
		update_god_mode_camera(delta)
	elif camera_mode != CameraMode.FIRST_PERSON:
		update_third_person_camera(delta)
		update_camera_tracking(delta)
		update_auto_rotation(delta)

func set_camera_mode(new_mode: CameraMode):
	camera_mode = new_mode
	update_camera_mode()

func update_camera_mode():
	match camera_mode:
		CameraMode.FIRST_PERSON:
			first_person_camera.current = true
			third_person_camera.current = false
			god_mode_camera.current = false
			# Hide player mesh in first person if visible
			if player.has_node("MeshInstance3D"):
				player.get_node("MeshInstance3D").visible = false
		CameraMode.GOD_MODE:
			first_person_camera.current = false
			third_person_camera.current = false
			god_mode_camera.current = true
			# Show player mesh in god mode
			if player.has_node("MeshInstance3D"):
				player.get_node("MeshInstance3D").visible = true
		_:
			first_person_camera.current = false
			third_person_camera.current = true
			god_mode_camera.current = false
			# Show player mesh in third person
			if player.has_node("MeshInstance3D"):
				player.get_node("MeshInstance3D").visible = true
			
			# Set target values for third person
			current_distance = third_person_distances.get(camera_mode, 4.0)
			current_height = third_person_heights.get(camera_mode, 2.0)
			current_angle = third_person_angles.get(camera_mode, -15.0)
			
			# Apply position immediately on mode change
			apply_third_person_position()
			# Force instant position if enabled
			if instant_switch:
				actual_position = desired_position
				actual_rotation = Vector3(deg_to_rad(current_angle), 0, 0)
				camera_arm.position = actual_position
				third_person_camera.rotation.x = actual_rotation.x

func update_third_person_camera(delta):
	# Get current mode settings
	var settings = tracking_settings.get(camera_mode, {"speed": 12.0, "offset": Vector3.ZERO})
	var mode_offset = settings.get("offset", Vector3.ZERO)
	
	# Calculate desired position: behind player at proper distance and height
	var base_position = Vector3(mode_offset.x, current_height - 1.6, -current_distance)
	desired_position = base_position
	desired_rotation = Vector3(deg_to_rad(current_angle), 0, 0)
	
	# Apply collision detection if enabled
	if collision_check:
		var checked_position = check_camera_collision(desired_position)
		if checked_position != desired_position:
			# Pull camera closer if collision detected
			desired_position = checked_position
	
	# Smooth camera movement and rotation
	if smooth_transition and not instant_switch:
		# Smooth position
		actual_position = actual_position.lerp(desired_position, position_smoothing * delta)
		camera_arm.position = actual_position
		
		# Smooth rotation
		actual_rotation.x = lerp_angle(actual_rotation.x, desired_rotation.x, rotation_smoothing * delta)
		third_person_camera.rotation.x = actual_rotation.x
	else:
		# Direct positioning
		actual_position = desired_position
		actual_rotation = desired_rotation
		camera_arm.position = actual_position
		third_person_camera.rotation = actual_rotation
	
	# Reset instant switch flag after first frame
	if instant_switch:
		instant_switch = false
	
	# Camera itself stays at origin of camera_arm
	third_person_camera.position = Vector3.ZERO

func apply_third_person_position():
	var settings = tracking_settings.get(camera_mode, {"speed": 12.0, "offset": Vector3.ZERO})
	var mode_offset = settings.get("offset", Vector3.ZERO)
	
	# Calculate desired position
	desired_position = Vector3(mode_offset.x, current_height - 1.6, -current_distance)
	desired_rotation = Vector3(deg_to_rad(current_angle), 0, 0)
	
	# Initialize actual position if needed
	if actual_position == Vector3.ZERO:
		actual_position = desired_position
		actual_rotation = desired_rotation
	
	# Position camera
	camera_arm.position = desired_position
	third_person_camera.position = Vector3.ZERO
	third_person_camera.rotation = desired_rotation
	camera_arm.rotation = Vector3.ZERO
	
	# Enable instant switch for next frame
	instant_switch = true

func update_camera_tracking(delta):
	# Track player movement for responsive camera behavior
	var current_velocity = player.velocity if player.velocity else Vector3.ZERO
	var velocity_change = current_velocity - last_player_velocity
	
	# Smooth velocity tracking
	camera_velocity = camera_velocity.lerp(velocity_change, velocity_smoothing)
	last_player_velocity = current_velocity
	
	# Adjust camera position based on movement direction
	if camera_mode != CameraMode.GOD_MODE and current_velocity.length() > 1.0:
		# Slightly lag camera behind movement direction for cinematic feel
		var movement_dir = current_velocity.normalized()
		var lag_offset = -movement_dir * 0.3 * current_velocity.length() * 0.1
		
		# Apply subtle camera shake for dynamic movement
		var shake_intensity = min(current_velocity.length() * 0.02, 0.1)
		var time = Time.get_ticks_msec() * 0.001  # Convert to seconds
		var shake = Vector3(
			sin(time * 15.0) * shake_intensity,
			cos(time * 12.0) * shake_intensity * 0.5,
			0
		)
		
		camera_pivot.position = Vector3(0, 1.6, 0) + lag_offset + shake
	else:
		# Return to neutral position when not moving
		camera_pivot.position = camera_pivot.position.lerp(Vector3(0, 1.6, 0), 5.0 * delta)

func update_auto_rotation(delta):
	# Auto-rotate camera to behind player when idle
	if not auto_rotate_enabled or camera_mode == CameraMode.GOD_MODE:
		return
	
	# Check if player is moving or mouse is being used
	var player_velocity = player.velocity if player.velocity else Vector3.ZERO
	var is_moving = player_velocity.length() > 0.1
	var mouse_input = Input.get_last_mouse_velocity().length() > 10.0
	
	if is_moving or mouse_input:
		idle_timer = 0.0
	else:
		idle_timer += delta
	
	# Start auto-rotation after idle threshold
	if idle_timer > idle_threshold:
		# Smoothly rotate camera to behind player
		var player_forward = -player.global_transform.basis.z
		var target_yaw = atan2(player_forward.x, player_forward.z)
		var current_yaw = camera_pivot.rotation.y
		
		# Smooth rotation towards target
		var yaw_diff = target_yaw - current_yaw
		# Handle angle wrapping
		if yaw_diff > PI:
			yaw_diff -= 2 * PI
		elif yaw_diff < -PI:
			yaw_diff += 2 * PI
		
		camera_pivot.rotation.y = lerp_angle(current_yaw, current_yaw + yaw_diff, auto_rotate_speed * delta)

func check_camera_collision(target_pos: Vector3) -> Vector3:
	# Cast ray from player to desired camera position
	var space_state = player.get_world_3d().direct_space_state
	var player_pos = camera_pivot.global_position
	var desired_global = camera_pivot.to_global(target_pos)
	
	var query = PhysicsRayQueryParameters3D.create(player_pos, desired_global)
	query.collision_mask = collision_mask
	query.exclude = [player]  # Don't collide with player
	
	var result = space_state.intersect_ray(query)
	if result:
		# Move camera closer to avoid clipping
		var hit_point = result.position
		var safe_distance = player_pos.distance_to(hit_point) - collision_offset
		var camera_direction = (desired_global - player_pos).normalized()
		var safe_position = player_pos + camera_direction * max(safe_distance, 1.0)  # Minimum 1 unit distance
		return camera_pivot.to_local(safe_position)
	
	return target_pos

func update_god_mode_camera(delta):
	# God mode camera - free flying camera with WASD + mouse
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
