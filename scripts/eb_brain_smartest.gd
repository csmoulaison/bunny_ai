class_name EbBrainSmartest extends EbBrain

enum ExploreState {
	MOVE,
	LISTEN,
	THINK
}

@export_group("Explore")
@export var exploration_distance_threshold: float = 10.0
@export var search_node_forget_per_second: float = 0.1
@export var search_node_explore_per_second: float = 0.5
@export var min_explore_speed: float = 3.0
@export var max_explore_speed: float = 6.0
@export var explore_speed_distance_multiplier: float = 1.0
@export_group("Hunting")
@export var min_hunt_speed: float = 2.0
@export var max_hunt_speed: float = 8.0
@export var player_guess_max_radius: float = 14.0
@export var player_guess_reset_distance_threshold: float = 6.0
@export var player_guess_velocity_depreciation_rate: float = 0.004
@export var sound_wall_obstruction_modifier: float = 0.25
@export var sound_obstacle_obstruction_modifier: float = 0.5
@export var player_guess_intensity_depreciation_rate: float = 0.01
@export var player_guess_radius_expansion_rate: float = 2.0
@export var player_kill_radius: float = 3.0
@export_group("Distractions")

@export_group("State lengths")
@export var min_move_seconds: float = 4.0
@export var max_move_seconds: float = 8.0
@export var min_listen_seconds: float = 3.0
@export var max_listen_seconds: float = 5.0
@export var min_think_seconds: float = 1.0
@export var max_think_seconds: float = 2.0
@export_group("Sound response curves")
@export var breath_response_curve: SoundCurve
@export var crouch_response_curve: SoundCurve
@export var walk_response_curve: SoundCurve
@export var run_response_curve: SoundCurve
@export var egg_response_curve: SoundCurve
@export var glass_response_curve: SoundCurve
@export var exhibit_response_curve: SoundCurve
@export var airhorn_response_curve: SoundCurve
# Exploration state
var explore_state: ExploreState = ExploreState.LISTEN
var search_nodes: Array[SearchNode]
var explore_nodes: Array[SearchNode]
var state_timer: float = 0.0
# Hunting state
var player_guess_center: Vector3 = Vector3.ZERO
var player_guess_velocity: Vector3 = Vector3.ZERO
var player_guess_radius: float = 0.0
var player_guess_intensity: float = 0.0
# Distraction state
var distraction_position: Vector3 = Vector3.ZERO
var distraction_timer: float = 0.0
# Airhorn state
var stun_timer: float = 0.0

func reset(core: EbCore):
	search_nodes = core._search_nodes
	explore_nodes = core._explore_nodes
	core.nav_goto_me()
	core.nav_set_speed(0.0)
	explore_state = ExploreState.LISTEN
	state_timer = 0.0
	player_guess_center = Vector3.ZERO
	player_guess_intensity = 0.0
	stun_timer = 0.0
	distraction_timer = 0.0
	
func update_explore_nodes(core: EbCore, dt: float) -> SearchNode:
	for node in explore_nodes:
		var distance = core.position().distance_to(node.global_position)
		var distance_contribution: float = lerp(-1.0, 1.0, clamp((distance / exploration_distance_threshold) / 2.0, 0.0, 1.0))
		if distance_contribution > 0.0: distance_contribution *= search_node_forget_per_second
		if distance_contribution < 0.0: distance_contribution *= search_node_explore_per_second
		node.score += distance_contribution * dt
		
		var player_distance = player_guess_center.distance_to(node.global_position)
		var player_contribution: float = lerp(1.0, -1.0, clamp((player_distance / player_guess_radius) / 2.0, 0.0, 1.0))
		player_contribution *= 0.1 * player_guess_intensity
		node.score += player_contribution * dt
	var highest_utility: float = 0.0
	var highest_utility_node: SearchNode = explore_nodes[0]
	for node in explore_nodes:
		var distance = core.position().distance_to(node.global_position)
		if node.score / (distance * 0.2) > highest_utility:
			highest_utility = node.score
			highest_utility_node = node
	return highest_utility_node

func take_action(core: EbCore, dt: float):
	var search_node: SearchNode = update_explore_nodes(core, dt)
	#player_guess_radius += clamp(player_guess_radius, 1.0, 8.0) * player_guess_radius_expansion_rate * dt
	player_guess_radius += player_guess_radius_expansion_rate * dt
	if player_guess_radius > player_guess_max_radius:
		player_guess_radius = player_guess_max_radius
	var distance_to_player_guess: float = core.position().distance_to(player_guess_center)
	if distance_to_player_guess < clamp(6.0, player_guess_radius, player_guess_radius):
		var intensity_distance_mod: float = 1.0 / clamp(0.1, distance_to_player_guess, distance_to_player_guess)
		player_guess_intensity = lerp(player_guess_intensity, 0.0, player_guess_intensity_depreciation_rate * intensity_distance_mod)
	# Move player guess
	player_guess_velocity = lerp(player_guess_velocity, Vector3.ZERO, player_guess_velocity_depreciation_rate)
	var space_state: PhysicsDirectSpaceState3D = core._root.get_world_3d().direct_space_state
	var ray_origin = Vector3(core.position().x, 4.0, core.position().z)
	var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + player_guess_velocity)
	var result = space_state.intersect_ray(ray_query)
	if !result.is_empty():
		player_guess_velocity = Vector3.ZERO
	player_guess_center += player_guess_velocity * dt
	
	stun_timer -= dt
	if stun_timer > 0.0:
		core.nav_goto_me()
		core.nav_set_speed(0.0)
		return
	
	# Are we distracted?
	if distraction_timer > 0.0:
		core.nav_goto_target(distraction_position)
		core.nav_set_speed(clamp((core.position().distance_to(core.nav_target_position()) - 4.0) * explore_speed_distance_multiplier, min_hunt_speed, max_hunt_speed))
		if core.position().distance_to(distraction_position) < 6.0:
			distraction_timer -= dt
		return
	
	# If we aren't distracted, do we have a guess of the player's whereabouts?
	if player_guess_intensity > 0.2:
		core.nav_set_speed(clamp((core.position().distance_to(core.nav_target_position()) - 4.0) * explore_speed_distance_multiplier, min_hunt_speed, max_hunt_speed))
		if core.nav_at_target():
			select_player_nav_target(core)
		return
	
	print("exploring ", Time.get_ticks_msec())
	# If we don't have a guess, start exploring
	match explore_state:
		ExploreState.MOVE:
			core.nav_set_speed(clamp((core.position().distance_to(core.nav_target_position()) - 4.0) * explore_speed_distance_multiplier, min_explore_speed, max_explore_speed))
			state_timer -= dt
			if state_timer < 0.0:
				core.nav_set_speed(0.0)
				state_timer = randf_range(min_listen_seconds, max_listen_seconds)
				explore_state = ExploreState.LISTEN
			if core.nav_at_target():
				if randf() > 0.5:
					core.nav_set_speed(0.0)
					state_timer = randf_range(min_think_seconds, max_think_seconds)
					explore_state = ExploreState.THINK
				else:
					core.nav_goto_target(search_node.global_position)
		ExploreState.LISTEN:
			state_timer -= dt
			if state_timer < 0.0:
				core.nav_goto_target(search_node.global_position)
				state_timer = randf_range(min_move_seconds, max_move_seconds)
				explore_state = ExploreState.MOVE
		ExploreState.THINK:
			state_timer -= dt
			if state_timer < 0.0:
				core.nav_goto_target(search_node.global_position)
				state_timer = randf_range(min_move_seconds, max_move_seconds)
				explore_state = ExploreState.MOVE

func respond_to_sound(core: EbCore, origin: Vector3, type: Sound.Type):
	var actual_distance: float = core.position().distance_to(origin) / 100.0
	var distance_score = actual_distance
	
	var space_state: PhysicsDirectSpaceState3D = core._root.get_world_3d().direct_space_state
	var ray_start = Vector3(core.position().x, 5.0, core.position().z)
	var ray_end = Vector3(origin.x, 5.0, origin.y)
	var ray_query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, 0)
	var result = space_state.intersect_ray(ray_query)
	if !result.is_empty():
		print("obstructed by wall")
		#distance_score *= 1.0 / sound_wall_obstruction_modifier
	else:
		ray_start = Vector3(core.position().x, 0.5, core.position().z)
		ray_end = Vector3(origin.x, 0.5, origin.y)
		ray_query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, 0)
		result = space_state.intersect_ray(ray_query)
		if !result.is_empty():
			print("obstructed by obstacle")
			#distance_score *= 1.0 / sound_obstacle_obstruction_modifier
	
	var response: float = 0.0
	var sound_implied_speed: float = 0.0 
	match type:
		Sound.Type.BREATH: response = breath_response_curve.sample(distance_score)
		Sound.Type.CROUCH_FOOTSTEP: 
			response = crouch_response_curve.sample(distance_score)
			sound_implied_speed = 1.0
		Sound.Type.WALK_FOOTSTEP: 
			response = walk_response_curve.sample(distance_score)
			sound_implied_speed = 3.0
		Sound.Type.RUN_FOOTSTEP: 
			response = run_response_curve.sample(distance_score)
			sound_implied_speed = 6.0
		Sound.Type.EGG_NORMAL: response = egg_response_curve.sample(distance_score)
		Sound.Type.EGG_GLASS: response = glass_response_curve.sample(distance_score)
		Sound.Type.EXHIBIT_RECORDING: response = exhibit_response_curve.sample(distance_score)
		Sound.Type.AIRHORN: response = airhorn_response_curve.sample(distance_score)
		
	if(type == Sound.Type.BREATH
	|| type == Sound.Type.CROUCH_FOOTSTEP
	|| type == Sound.Type.WALK_FOOTSTEP
	|| type == Sound.Type.RUN_FOOTSTEP):
		if core.position().distance_to(origin) < player_kill_radius:
			core.kill_player()
			reset(core)
			
		# TODO(conner): Lerp position, velocity, and (radius towards 0)
		if player_guess_center.distance_to(origin) > player_guess_reset_distance_threshold:
			player_guess_center = origin
			player_guess_radius = lerp(player_guess_max_radius, 0.0, response)
			player_guess_velocity = Vector3.ZERO
		else:
			var implied_velocity: Vector3 = (origin - player_guess_center).normalized() * sound_implied_speed
			player_guess_velocity = lerp(player_guess_velocity, implied_velocity, response)
			player_guess_radius = lerp(player_guess_radius, 0.0, response)
			player_guess_center = lerp(player_guess_center, origin, response)
			player_guess_intensity = lerp(player_guess_intensity, 1.0, response)
		if player_guess_intensity > 0.1:
			select_player_nav_target(core)
	else: if(type == Sound.Type.EGG_NORMAL
	|| type == Sound.Type.EGG_GLASS
	|| type == Sound.Type.EXHIBIT_RECORDING):
		distraction_timer = 10.0 * response
		distraction_position = origin
	else: if(type == Sound.Type.AIRHORN):
		stun_timer = 6.0

func select_player_nav_target(core: EbCore):
	var eligible_nodes: Array[SearchNode]
	for node in search_nodes:
		if player_guess_center.distance_to(node.position) < player_guess_radius:
			eligible_nodes.push_back(node)
	if eligible_nodes.is_empty():
		core.nav_goto_target(player_guess_center)
	else:
		core.nav_goto_target(eligible_nodes[randi_range(0, eligible_nodes.size() - 1)].position)
