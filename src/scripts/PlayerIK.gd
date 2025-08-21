extends Node3D

# IK system for player foot placement
# Requires a skeleton with leg bones and IK targets

@export var skeleton: Skeleton3D
@export var left_foot_ik: SkeletonIK3D
@export var right_foot_ik: SkeletonIK3D
@export var raycast_distance: float = 2.0
@export var foot_offset: float = 0.1
@export var interpolation_speed: float = 10.0
@export var max_foot_distance: float = 0.5

var left_foot_target: Vector3
var right_foot_target: Vector3
var left_foot_position: Vector3
var right_foot_position: Vector3

@onready var space_state = get_world_3d().direct_space_state

func _ready():
	if not skeleton:
		push_error("PlayerIK: No skeleton assigned!")
		set_physics_process(false)
		return
		
	# Initialize foot positions
	if left_foot_ik:
		left_foot_position = left_foot_ik.get_target_transform().origin
		left_foot_target = left_foot_position
		
	if right_foot_ik:
		right_foot_position = right_foot_ik.get_target_transform().origin
		right_foot_target = right_foot_position

func _physics_process(delta):
	if not skeleton:
		return
		
	# Cast rays down from each foot to find ground
	update_foot_placement(left_foot_ik, left_foot_target, left_foot_position, delta)
	update_foot_placement(right_foot_ik, right_foot_target, right_foot_position, delta)

func update_foot_placement(foot_ik: SkeletonIK3D, target: Vector3, current_pos: Vector3, delta: float):
	if not foot_ik:
		return
		
	# Get the foot bone's world position
	var foot_bone_id = foot_ik.get_tip_bone()
	var foot_transform = skeleton.global_transform * skeleton.get_bone_global_pose(foot_bone_id)
	var foot_origin = foot_transform.origin
	
	# Cast ray down from foot position
	var ray_start = foot_origin + Vector3(0, 0.5, 0)
	var ray_end = foot_origin + Vector3(0, -raycast_distance, 0)
	
	var ray_params = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	ray_params.exclude = [get_parent()] # Exclude the player
	ray_params.collision_mask = 1 # Only check against ground layer
	
	var result = space_state.intersect_ray(ray_params)
	
	if result:
		# Found ground - place foot with offset
		var new_target = result.position + Vector3(0, foot_offset, 0)
		
		# Clamp foot movement to prevent overextension
		var hip_position = foot_origin + Vector3(0, max_foot_distance, 0)
		if new_target.distance_to(hip_position) > max_foot_distance:
			var direction = (new_target - hip_position).normalized()
			new_target = hip_position + direction * max_foot_distance
		
		target = new_target
	else:
		# No ground found - use default position
		var default_transform = foot_ik.get_target_transform()
		target = skeleton.global_transform * default_transform.origin
	
	# Smoothly interpolate to target position
	current_pos = current_pos.lerp(target, interpolation_speed * delta)
	
	# Update IK target
	var ik_transform = foot_ik.get_target_transform()
	ik_transform.origin = skeleton.global_transform.inverse() * current_pos
	foot_ik.set_target_transform(ik_transform)
	
	# Store the positions for next frame
	if foot_ik == left_foot_ik:
		left_foot_target = target
		left_foot_position = current_pos
	else:
		right_foot_target = target
		right_foot_position = current_pos

func set_ik_enabled(enabled: bool):
	if left_foot_ik:
		left_foot_ik.start(enabled)
	if right_foot_ik:
		right_foot_ik.start(enabled)