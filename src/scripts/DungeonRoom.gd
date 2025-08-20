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