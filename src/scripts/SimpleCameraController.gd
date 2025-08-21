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

var player: CharacterBody3D
var camera_pivot: Node3D
var camera_holder: Node3D
var current_camera: Camera3D

# Camera distances
var camera_distances = {
	CameraMode.OVER_THE_SHOULDER: {"distance": 2.0, "height": 0.5, "side": 0.6},
	CameraMode.THIRD_PERSON_CLOSE: {"distance": 4.0, "height": 1.0, "side": 0},
	CameraMode.THIRD_PERSON_MEDIUM: {"distance": 7.0, "height": 2.0, "side": 0},
	CameraMode.THIRD_PERSON_FAR: {"distance": 12.0, "height": 3.0, "side": 0},
}

func _ready():
	player = get_parent() as CharacterBody3D
	
	# Create camera pivot at player eye level
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0, 1.5, 0)
	player.add_child(camera_pivot)
	
	# Create camera holder that will move around the pivot
	camera_holder = Node3D.new()
	camera_holder.name = "CameraHolder"
	camera_pivot.add_child(camera_holder)
	
	# Create the actual camera
	current_camera = Camera3D.new()
	current_camera.name = "MainCamera"
	current_camera.fov = 75.0
	camera_holder.add_child(current_camera)
	
	# Get reference to first person camera and disable it
	var first_person_cam = player.get_node_or_null("Camera3D")
	if first_person_cam:
		first_person_cam.current = false
	
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
		var delta = event.relative * mouse_sensitivity
		
		if camera_mode == CameraMode.FIRST_PERSON:
			player.rotate_y(-delta.x)
			current_camera.rotate_x(-delta.y)
			current_camera.rotation.x = clamp(current_camera.rotation.x, -PI/2, PI/2)
		else:
			# Rotate camera around player for third person
			camera_pivot.rotate_y(-delta.x)
			camera_holder.rotate_x(-delta.y)
			camera_holder.rotation.x = clamp(camera_holder.rotation.x, -PI/3, PI/6)

func set_camera_mode(mode: CameraMode):
	camera_mode = mode
	update_camera_mode()

func update_camera_mode():
	print("\nSwitching to: ", get_mode_name())
	
	# Show/hide player mesh
	var mesh = player.get_node_or_null("MeshInstance3D")
	if mesh:
		mesh.visible = (camera_mode != CameraMode.FIRST_PERSON)
	
	# Position camera based on mode
	match camera_mode:
		CameraMode.FIRST_PERSON:
			camera_holder.position = Vector3(0, 0, 0)
			current_camera.position = Vector3(0, 0, 0)
			
		CameraMode.GOD_MODE:
			camera_holder.position = Vector3(0, 5, 10)
			current_camera.position = Vector3(0, 0, 0)
			
		_:
			# Third person modes
			var config = camera_distances.get(camera_mode, {"distance": 5, "height": 1, "side": 0})
			var dist = config["distance"]
			var height = config["height"]
			var side = config["side"]
			
			camera_holder.position = Vector3(side, height, dist)
			current_camera.position = Vector3(0, 0, 0)
			
			print("Camera positioned at: ", camera_holder.position)
			print("Camera global position: ", current_camera.global_position)
	
	# Always ensure our camera is current
	current_camera.current = true

func get_mode_name() -> String:
	match camera_mode:
		CameraMode.FIRST_PERSON: return "First Person"
		CameraMode.OVER_THE_SHOULDER: return "Over The Shoulder"
		CameraMode.THIRD_PERSON_CLOSE: return "Third Person - Close"
		CameraMode.THIRD_PERSON_MEDIUM: return "Third Person - Medium"
		CameraMode.THIRD_PERSON_FAR: return "Third Person - Far"
		CameraMode.GOD_MODE: return "God Mode"
		_: return "Unknown"

func _process(delta):
	if camera_mode == CameraMode.GOD_MODE:
		# Free fly controls for god mode
		var speed = 10.0
		if Input.is_action_pressed("sprint"):
			speed *= 2.0
		
		var input = Vector3()
		input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward") 
		input.y = Input.get_action_strength("jump") - Input.get_action_strength("move_down")
		
		var movement = current_camera.global_transform.basis * input
		camera_pivot.global_position += movement.normalized() * speed * delta