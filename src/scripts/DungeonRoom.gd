extends Node3D

@export var player_scene: PackedScene = preload("res://src/scenes/Player.tscn")

func _ready():
	print("Dungeon room loaded")
	spawn_player()
	
func spawn_player():
	var player = player_scene.instantiate()
	add_child(player)
	
	var spawn_point = $PlayerSpawn
	if spawn_point:
		player.global_position = spawn_point.global_position
	else:
		player.global_position = Vector3(0, 1, 8)
	
	# Disable the static camera since player has its own
	if has_node("Camera3D"):
		$Camera3D.current = false
	
	# Connect player to debug/dev systems
	connect_player_to_systems(player)

func connect_player_to_systems(player: Node3D):
	# Connect to debug overlay
	if GameManager.debug_overlay and GameManager.debug_overlay.has_method("set_player_reference"):
		GameManager.debug_overlay.set_player_reference(player)
	
	# Connect to movement tuner
	if GameManager.movement_tuner and GameManager.movement_tuner.has_method("set_player_reference"):
		GameManager.movement_tuner.set_player_reference(player)
	
	# Connect to camera overlay
	if GameManager.camera_overlay and GameManager.camera_overlay.has_method("set_camera_controller"):
		var camera_controller = player.get_node("CameraController")
		if camera_controller:
			GameManager.camera_overlay.set_camera_controller(camera_controller)