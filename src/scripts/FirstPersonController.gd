extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 6.0
const MOUSE_SENSITIVITY = 0.002
const GAMEPAD_SENSITIVITY = 2.0
const NOCLIP_SPEED = 10.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var noclip_enabled = false

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
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)
	
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
		camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)

func _physics_process(delta):
	if noclip_enabled:
		handle_noclip_movement(delta)
	else:
		handle_normal_movement(delta)
	
	move_and_slide()

func handle_normal_movement(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get input direction using our custom actions
	var input_dir = Vector2()
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	
	# Transform input to world space
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 5)
		velocity.z = move_toward(velocity.z, 0, SPEED * delta * 5)

func handle_noclip_movement(delta):
	# Get input direction
	var input_dir = Vector3()
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	input_dir.y = Input.get_action_strength("jump") - Input.get_action_strength("move_down")
	
	# Transform to camera space for true free flight
	var cam_transform = camera.global_transform
	var movement = cam_transform.basis * input_dir
	
	velocity = movement.normalized() * NOCLIP_SPEED

func toggle_noclip():
	noclip_enabled = !noclip_enabled
	if noclip_enabled:
		set_collision_mask_value(1, false) # Disable collision with layer 1
	else:
		set_collision_mask_value(1, true) # Re-enable collision