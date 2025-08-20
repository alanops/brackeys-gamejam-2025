extends Node3D

func _ready():
	print("Dungeon room loaded")
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://src/scenes/Main.tscn")