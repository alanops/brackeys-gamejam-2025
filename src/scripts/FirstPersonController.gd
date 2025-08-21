extends CharacterBody3D

# Movement constants
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.5
const JUMP_VELOCITY = 6.0
const ACCELERATION = 10.0
const FRICTION = 12.0
const AIR_ACCELERATION = 2.0
const AIR_FRICTION = 1.0

# Step-up system
const MAX_STEP_HEIGHT = 0.5
const STEP_UP_RAYCAST_LENGTH = 0.8

# Look sensitivity
const MOUSE_SENSITIVITY = 0.002
const GAMEPAD_SENSITIVITY = 2.0

# Noclip
const NOCLIP_SPEED = 10.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var noclip_enabled = false
var mouse_sensitivity_multiplier = 1.0

# Dynamic movement parameters (can be modified by MovementTuner)
var walk_speed = WALK_SPEED
var sprint_speed = SPRINT_SPEED
var jump_velocity = JUMP_VELOCITY
var acceleration = ACCELERATION
var friction = FRICTION
var air_acceleration = AIR_ACCELERATION
var air_friction = AIR_FRICTION
var step_up_velocity = 5.0
var max_step_height = MAX_STEP_HEIGHT
var mouse_sensitivity = MOUSE_SENSITIVITY

@onready var camera = $Camera3D

func _ready():
	add_to_group("player")
	# Capture mouse immediately on desktop, but not on web (requires user interaction)
	if not OS.has_feature("web"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Click to capture mouse (required for web)
	if event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return
	
	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_delta = event.relative * mouse_sensitivity * mouse_sensitivity_multiplier
		rotate_y(-mouse_delta.x)
		camera.rotate_x(-mouse_delta.y)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	# Pause/menu
	if event.is_action_pressed("pause"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			get_tree().change_scene_to_file("res://src/scenes/Main.tscn")
	
	# Reset scene
	if event.is_action_pressed("reset_scene"):
		get_tree().reload_current_scene()
	
	# Toggle noclip
	if event.is_action_pressed("toggle_noclip"):
		toggle_noclip()

func _process(delta):
	# Gamepad look
	var look_input = Vector2(
		Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	)
	
	if look_input.length() > 0.1:
		rotate_y(-look_input.x * GAMEPAD_SENSITIVITY * delta)
		camera.rotate_x(-look_input.y * GAMEPAD_SENSITIVITY * delta)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	if noclip_enabled:
		handle_noclip_movement(delta)
	else:
		handle_normal_movement(delta)
	
	move_and_slide()
	
	# Handle step-up after moving to detect collisions
	if not noclip_enabled and is_on_floor():
		handle_step_up(delta)

func handle_normal_movement(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get input direction
	var input_dir = Vector2()
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	
	# Transform input to world space
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Determine current speed based on sprinting
	var current_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	
	# Get current acceleration and friction values
	var accel = acceleration if is_on_floor() else air_acceleration
	var friction_val = friction if is_on_floor() else air_friction
	
	# Apply movement with smooth acceleration/deceleration
	if direction:
		# Accelerate towards target velocity
		var target_velocity = direction * current_speed
		velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)
	else:
		# Apply friction when no input
		velocity.x = move_toward(velocity.x, 0, friction_val * delta)
		velocity.z = move_toward(velocity.z, 0, friction_val * delta)

func handle_noclip_movement(delta):
	# Get input direction
	var input_dir = Vector3()
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	input_dir.y = Input.get_action_strength("jump") - Input.get_action_strength("move_down")
	
	# Transform to camera space for true free flight
	var cam_transform = camera.global_transform
	var movement = cam_transform.basis * input_dir
	
	# Apply sprint multiplier to noclip
	var speed_multiplier = 1.7 if Input.is_action_pressed("sprint") else 1.0
	velocity = movement.normalized() * NOCLIP_SPEED * speed_multiplier

func handle_step_up(delta):
	# Only try step-up if we're moving horizontally and not already going up
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	if horizontal_velocity.length() < 0.1 or velocity.y > 1.0:
		return
		
	# Check if we collided with something while moving forward
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collision_normal = collision.get_normal()
		
		# Only help with forward-facing walls (not side-sliding)
		var movement_dot = horizontal_velocity.normalized().dot(-collision_normal)
		if movement_dot < 0.5:  # We're not moving directly into the wall
			continue
			
		# If we hit a wall (normal pointing roughly horizontal)
		if abs(collision_normal.y) < 0.6:
			# Check if the collision point is low enough to be a step
			var collision_height = collision.get_position().y - global_position.y
			if collision_height > -0.8 and collision_height < max_step_height:
				# Add gentle upward velocity - much more subtle
				velocity.y = max(velocity.y, step_up_velocity * 0.4)
				break  # Only help with one step at a time

func set_movement_parameter(param_name: String, value: float):
	match param_name:
		"walk_speed":
			walk_speed = value
			print("Player walk_speed set to: ", value)
		"sprint_speed":
			sprint_speed = value
			print("Player sprint_speed set to: ", value)
		"jump_velocity":
			jump_velocity = value
			print("Player jump_velocity set to: ", value)
		"acceleration":
			acceleration = value
			print("Player acceleration set to: ", value)
		"friction":
			friction = value
			print("Player friction set to: ", value)
		"air_acceleration":
			air_acceleration = value
		"air_friction":
			air_friction = value
		"step_up_velocity":
			step_up_velocity = value
			print("Player step_up_velocity set to: ", value)
		"max_step_height":
			max_step_height = value
		"mouse_sensitivity":
			mouse_sensitivity = value

func toggle_noclip():
	noclip_enabled = !noclip_enabled
	if noclip_enabled:
		set_collision_mask_value(1, false) # Disable collision with layer 1
	else:
		set_collision_mask_value(1, true) # Re-enable collision