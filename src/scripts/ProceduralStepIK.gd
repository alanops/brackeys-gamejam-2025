extends Node3D

# Procedural IK system for smooth stair climbing
# This adjusts the player's height based on foot placement

@export var step_height_offset: float = 0.2
@export var smoothing_speed: float = 8.0
@export var ray_distance: float = 1.5
@export var foot_spacing: float = 0.3
@export var enabled: bool = true

var player: CharacterBody3D
var current_height_offset: float = 0.0
var target_height_offset: float = 0.0

func _ready():
	player = get_parent() as CharacterBody3D
	if not player:
		push_error("ProceduralStepIK must be child of CharacterBody3D")
		set_physics_process(false)

func _physics_process(delta):
	if not enabled or not player:
		return
		
	# Only apply IK when on ground and moving slowly (not jumping)
	if not player.is_on_floor() or abs(player.velocity.y) > 2.0:
		target_height_offset = 0.0
		current_height_offset = lerp(current_height_offset, target_height_offset, smoothing_speed * delta)
		return
	
	# Cast rays for "virtual feet"
	var space_state = get_world_3d().direct_space_state
	var player_pos = player.global_position
	var movement_dir = Vector3(player.velocity.x, 0, player.velocity.z).normalized()
	
	# Calculate foot positions based on movement direction
	var left_foot_pos = player_pos + Vector3(-foot_spacing, 0, 0).rotated(Vector3.UP, atan2(movement_dir.x, movement_dir.z))
	var right_foot_pos = player_pos + Vector3(foot_spacing, 0, 0).rotated(Vector3.UP, atan2(movement_dir.x, movement_dir.z))
	var center_pos = player_pos + movement_dir * 0.3 # Look slightly ahead
	
	# Cast rays from each foot position
	var heights = []
	for foot_pos in [left_foot_pos, right_foot_pos, center_pos]:
		var ray_params = PhysicsRayQueryParameters3D.create(
			foot_pos + Vector3(0, 0.5, 0),
			foot_pos + Vector3(0, -ray_distance, 0)
		)
		ray_params.exclude = [player]
		ray_params.collision_mask = 1
		
		var result = space_state.intersect_ray(ray_params)
		if result:
			var ground_height = result.position.y
			var ideal_player_height = ground_height + step_height_offset
			var height_diff = ideal_player_height - player_pos.y
			
			# Only adjust if we need to step up (not down)
			if height_diff > -0.1 and height_diff < 0.5:
				heights.append(height_diff)
	
	# Use the highest point (to ensure we clear all obstacles)
	if heights.size() > 0:
		target_height_offset = heights.max()
	else:
		target_height_offset = 0.0
	
	# Smooth the height adjustment
	current_height_offset = lerp(current_height_offset, target_height_offset, smoothing_speed * delta)
	
	# Apply the height offset to the player
	if abs(current_height_offset) > 0.01:
		player.position.y += current_height_offset * delta * smoothing_speed

func set_enabled(value: bool):
	enabled = value
	if not enabled:
		current_height_offset = 0.0
		target_height_offset = 0.0