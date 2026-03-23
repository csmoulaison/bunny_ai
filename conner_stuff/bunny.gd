class_name Bunny extends CharacterBody3D

class QueuedSound:
	var origin: Vector3
	var type: Sound.Type
	func _init(org: Vector3, typ: Sound.Type):
		origin = org
		type = typ

enum ExploreBehavior {
	ZONE_STATIC,
	ZONE_FOLLOW_GUESS,
	ZONE_FOLLOW_PLAYER,
	RADIUS_STATIC,
	RADIUS_FOLLOW_PLAYER,
	PATROL,
	ALWAYS_HUNT,
	STAY_IN_PLACE
}

enum ExploreState {
	MOVE,
	LISTEN,
	THINK
}

signal player_killed()

@export var stats: BunnyStats
## This property should be set up to reference the SearchZoneParent node.[br][br]
## The [SearchZone] nodes used by EB to explore and pathfind are assumed to be 
## set up as children of a single parent node and as parents of multiple 
## [SearchNode] nodes, with the hierarchical structure being as follows:[br][br]
## [center][b]SearchZonesParent[/b] -> [SearchZone] -> [SearchNode].[/center][br][br]
@export var search_zones_parent: Node3D
## You can turn off EB's ability to hunt the player by setting this to 
## [b]false[/b].
@export var can_hunt_player: bool = true
## If this is set to [b]false[/b], situations which would normally kill the 
## player will not. Useful for testing functionality without interruption.
@export var can_kill_player: bool = true
## If this is set to [b]true[/b], debug visualizers will be made active. If not,
## the associated nodes will be deleted on game start.
@export var use_debug_info: bool = true
@export_group("Explore")
## Determines the default set of behaviors that EB follows when he is not either
## currently hunting the player, distracted, or stunned.
@export var explore_behavior: ExploreBehavior = ExploreBehavior.ZONE_STATIC
## The [SearchZone] nodes in this array define the set of nodes which EB will 
## try to explore when he isn't in another state such as following the player or
## being distracted.
## [br][br]If using multiple zones, they should probably all be adjacent, 
## otherwise poor EB is going to have a hard time going back and forth trying to
## explore.
@export var static_explore_zones: Array[SearchZone]
## If using the patrol path cycle idle behavior, EB will patrol between the 
## nodes in this array cyclically
@export var patrol_path: Array[Node3D]
@export_group("Sound response curves")
## Sets EB's response to breath sounds. See [SoundCurve] for more information.
@export var breath_response_curve: SoundCurve
## Sets EB's response to crouch sounds. See [SoundCurve] for more information.
@export var crouch_response_curve: SoundCurve
## Sets EB's response to walk sounds. See [SoundCurve] for more information.
@export var walk_response_curve: SoundCurve
## Sets EB's response to run sounds. See [SoundCurve] for more information.
@export var run_response_curve: SoundCurve
## Sets EB's response to sounds from eggs thrown against the floor and walls.
## See [SoundCurve] for more information.
@export var egg_response_curve: SoundCurve
## Sets EB's response to sounds from eggs being thrown into distraction objects.
## See [SoundCurve] for more information.
@export var glass_response_curve: SoundCurve
## Sets EB's response to sounds from exhibit recordings. See [SoundCurve] for 
## more information.
@export var exhibit_response_curve: SoundCurve
## Sets EB's response to airhorn sounds. See [SoundCurve] for more information.
## [br][br]Right now, EB is stunned when the response goes above a certain 
## threshold, but I'm going change the airhorn stuff to be based on a definite
## radius and this response curve will then define how long he is stunned for
## depending on the distance.
@export var airhorn_response_curve: SoundCurve
@export_group("Locomotion")
## Determines the distance from the target node that the pathfinding system will
## consider as having arrived. This should be set low, but not too low.
## Something like [b]0.1[/b] seems fine.
@export var nav_stop_distance: float = 0.1
## Determines how quickly EB changes his velocity when stopping, starting, or
## changing direction.
@export var acceleration: float = 20.0

@onready var pivot: Node3D = $Pivot
@onready var nav: NavigationAgent3D = $NavAgent

var player: Node3D
var speed: float = 0.0
var sound_queue: Array[QueuedSound]
var explore_state: ExploreState = ExploreState.LISTEN
var search_zones: Array[SearchZone]
var search_nodes: Array[SearchNode]
var explore_node_indices: PackedInt32Array
var state_timer: float = 0.0
var explore_point_center: Vector3 = Vector3.ZERO
var explore_point_radius: float = 5.0
# Hunting state
var player_hunt_target: Vector3 = Vector3.ZERO
var player_guess_center: Vector3 = Vector3.ZERO
var player_guess_velocity: Vector3 = Vector3.ZERO
var player_guess_radius: float = 0.0
var player_guess_zones: Array[SearchZone]
var player_guess_intensity: float = 0.0
# Distraction state
var distraction_position: Vector3 = Vector3.ZERO
var distraction_timer: float = 0.0
# Airhorn state
var stun_timer: float = 0.0
# Guard node specific
var nearby_guard_nodes: Array[SearchNode]
# Patrol node cycle specific
var current_patrol_node: int = 0


########################
# HIGH LEVEL FUNCTIONS #
########################

func reset():
	nav_set_speed(0.0)
	nav_goto_me()
	velocity = Vector3.ZERO
	explore_state = ExploreState.LISTEN
	state_timer = 0.0
	player_guess_center = Vector3.ZERO
	player_guess_intensity = 0.0
	stun_timer = 0.0
	distraction_timer = 0.0
	player_guess_zones.clear()
	
	match explore_behavior:
		ExploreBehavior.ZONE_STATIC:
			_on_set_explore_zone_static(static_explore_zones)
		ExploreBehavior.ZONE_FOLLOW_GUESS:
			_on_set_explore_zone_follow_guess(static_explore_zones)
		ExploreBehavior.ZONE_FOLLOW_PLAYER:
			_on_set_explore_zone_follow_player()
		ExploreBehavior.RADIUS_STATIC:
			_on_set_explore_radius_static(explore_point_center, explore_point_radius)
		ExploreBehavior.RADIUS_FOLLOW_PLAYER:
			_on_set_explore_radius_follow_player(explore_point_radius)
		ExploreBehavior.PATROL:
			_on_set_explore_patrol(patrol_path)
		ExploreBehavior.STAY_IN_PLACE:
			_on_set_explore_stay_in_place(explore_point_center)
		ExploreBehavior.ALWAYS_HUNT:
			_on_set_explore_always_hunt()

func _ready():
	if !use_debug_info:
		$DebugVisualizers.queue_free()
	
	player = get_tree().get_first_node_in_group("Player")
	
	# Listen for event emitters
	var event_emitter = get_tree().get_nodes_in_group("EbEventEmitter")
	for emitter in event_emitter:
		var signal_list = emitter.get_signal_list()
		for signal_dictionary in signal_list:
			if signal_dictionary.name == "eb_sound":
				emitter.eb_sound.connect(_on_sound)
			if signal_dictionary.name == "eb_set_stats":
				emitter.eb_set_stats.connect(_on_set_stats)
			if signal_dictionary.name == "eb_set_can_hunt_player":
				emitter.eb_set_can_hunt_player.connect(_on_set_can_hunt_player)
			if signal_dictionary.name == "eb_set_can_kill_player":
				emitter.eb_set_can_kill_player.connect(_on_set_can_kill_player)
			if signal_dictionary.name == "eb_set_explore_zone_static":
				emitter.eb_set_explore_zone_static.connect(_on_set_explore_zone_static)
			if signal_dictionary.name == "eb_set_explore_zone_follow_guess":
				emitter.eb_set_explore_zone_follow_guess.connect(_on_set_explore_zone_follow_guess)
			if signal_dictionary.name == "eb_set_explore_zone_follow_player":
				emitter.eb_set_explore_zone_follow_player.connect(_on_set_explore_zone_follow_player)
			if signal_dictionary.name == "eb_set_explore_radius_static":
				emitter.eb_set_explore_radius_static.connect(_on_set_explore_radius_static)
			if signal_dictionary.name == "eb_set_explore_radius_follow_player":
				emitter.eb_set_explore_radius_follow_player.connect(_on_set_explore_radius_follow_player)
			if signal_dictionary.name == "eb_set_explore_patrol":
				emitter.eb_set_explore_patrol.connect(_on_set_explore_patrol)
			if signal_dictionary.name == "eb_set_explore_always_hunt":
				emitter.eb_set_explore_always_hunt.connect(_on_set_explore_always_hunt)
			if signal_dictionary.name == "eb_set_explore_stay_in_place":
				emitter.eb_set_explore_stay_in_place.connect(_on_set_explore_stay_in_place)

	# Populate search nodes
	var tmp_zones = search_zones_parent.get_children()
	for zone in tmp_zones:
		if zone is SearchZone:
			search_zones.push_back(zone as SearchZone)
		var nodes: Array[Node] = zone.get_children()
		for node in nodes:
			if node is SearchNode:
				print("search node back!")
				search_nodes.push_back(node)

	# Initialize state
	reset()

func _process(dt: float):	
	# Are we stunned?
	stun_timer -= dt
	if stun_timer > 0.0:
		nav_goto_me()
		nav_set_speed(0.0)
		return
	
	# If we aren't stunned, are we distracted?
	if distraction_timer > 0.0:
		nav_goto_target(distraction_position)
		nav_set_distance_attenuated_speed(stats.distracted_speed_distance_multiplier, stats.min_distracted_speed, stats.max_distracted_speed)
		if global_position.distance_to(distraction_position) < 6.0:
			distraction_timer -= dt
		return
		
	# Do we have a guess of the player's whereabouts?
	if explore_behavior == ExploreBehavior.ALWAYS_HUNT || (can_hunt_player && player_guess_intensity > 0.2):
		nav_set_distance_attenuated_speed(stats.hunt_speed_distance_multiplier, stats.min_hunt_speed, stats.max_hunt_speed)
		if nav_at_target():
			select_player_hunt_target()
		nav_goto_target(player_hunt_target)
		return
	
	# If we aren't distracted, follow our explore behavior.
	match explore_behavior:
		ExploreBehavior.ZONE_STATIC:
			generate_explore_nodes_from_zones(static_explore_zones)
			update_and_explore_nodes(dt)
		ExploreBehavior.ZONE_FOLLOW_GUESS:
			generate_explore_nodes_from_zone_at_position(player_guess_center)
			update_and_explore_nodes(dt)
		ExploreBehavior.ZONE_FOLLOW_PLAYER:
			generate_explore_nodes_from_zone_at_position(player.global_position)
			update_and_explore_nodes(dt)
		ExploreBehavior.RADIUS_STATIC:
			generate_explore_nodes_from_point(explore_point_center, explore_point_radius)
			update_and_explore_nodes(dt)
		ExploreBehavior.RADIUS_FOLLOW_PLAYER:
			generate_explore_nodes_from_point(player.global_position, explore_point_radius)
			update_and_explore_nodes(dt)
		ExploreBehavior.PATROL:
			if explore_traverse_is_ready_for_target(dt):
				current_patrol_node += 1
				if current_patrol_node >= patrol_path.size(): current_patrol_node = 0
				nav_goto_target(patrol_path[current_patrol_node].global_position)
		ExploreBehavior.ALWAYS_HUNT:
			# NOTE: The ALWAYS_HUNT behavior made it so that we should never reach this
			# point, as its part of the hunt behavior conditional statement above.
			print("Tell Conner: Explore behavior set to ALWAYS_HUNT, but we've reached the explore behavior state machine. Why?")
		ExploreBehavior.STAY_IN_PLACE:
			nav_goto_target(explore_point_center)
			if nav_at_target(): nav_goto_me()

func _physics_process(dt: float):
	for sound in sound_queue:
		process_sound(sound.origin, sound.type)
	sound_queue.clear()
	
	#player_guess_radius += clamp(player_guess_radius, 1.0, 8.0) * player_guess_radius_expansion_rate * dt
	player_guess_radius += stats.player_guess_radius_expansion_rate * dt
	if player_guess_radius > stats.player_guess_max_radius:
		player_guess_radius = stats.player_guess_max_radius
	var distance_to_player_guess: float = global_position.distance_to(player_guess_center)
	if distance_to_player_guess < clamp(6.0, player_guess_radius, player_guess_radius):
		var intensity_distance_mod: float = 1.0 / clamp(0.1, distance_to_player_guess, distance_to_player_guess)
		player_guess_intensity = lerp(player_guess_intensity, 0.0, stats.player_guess_intensity_depreciation_rate * intensity_distance_mod)
	# Move player guess
	player_guess_velocity = lerp(player_guess_velocity, Vector3.ZERO, stats.player_guess_velocity_depreciation_rate)
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var ray_origin = Vector3(player_guess_center.x, 1.0, player_guess_center.z)
	var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + player_guess_velocity * dt * 2.0, 0b00000000_00000000_00000000_00000110)
	var result = space_state.intersect_ray(ray_query)
	if !result.is_empty():
		player_guess_velocity = Vector3.ZERO
	player_guess_center += player_guess_velocity * dt
	# update_zones_at_position(player_guess_center, player_guess_zones)
	
	var desired_velocity: Vector3 = Vector3.ZERO
	var target = nav.get_next_path_position()
	var delta: Vector3 = target - global_transform.origin;

	if delta.length() > nav_stop_distance:
		desired_velocity = delta.normalized() * speed
		pivot.rotation.y = atan2(desired_velocity.x, desired_velocity.z)
	else:
		nav.target_position = global_position
	velocity = velocity.move_toward(desired_velocity, acceleration * dt)
	move_and_slide()

func process_sound(origin: Vector3, type: Sound.Type):
	var actual_distance: float = global_position.distance_to(origin) / 100.0
	var distance_score = actual_distance
	
	if type == Sound.Type.AIRHORN && actual_distance < stats.airhorn_stun_radius:
		stun_timer = airhorn_response_curve.sample(distance_score)
		if stun_timer < 2.0: stun_timer = 2.0
		return
	
	if(type != Sound.Type.EGG_NORMAL
	&& type != Sound.Type.EGG_GLASS
	&& type != Sound.Type.EXHIBIT_RECORDING):
		var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var ray_start = Vector3(global_position.x, 2.5, global_position.z)
		var ray_end = origin
		var ray_query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, 0b00000000_00000000_00000000_00000010)
		var result = space_state.intersect_ray(ray_query)
		print("Checking obstruction:")
		if !result.is_empty():
			print("  Obstructed by wall.")
			distance_score /= stats.sound_wall_obstruction_modifier
		else:
			ray_query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, 0b00000000_00000000_00000000_00000100)
			result = space_state.intersect_ray(ray_query)
			if !result.is_empty():
				print("  Obstructed by obstacle.")
				distance_score /= stats.sound_obstacle_obstruction_modifier
	
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
	
	if response <= 0.01:
		return
		
	if(type == Sound.Type.BREATH
	|| type == Sound.Type.CROUCH_FOOTSTEP
	|| type == Sound.Type.WALK_FOOTSTEP
	|| type == Sound.Type.RUN_FOOTSTEP):
		if global_position.distance_to(origin) < stats.player_kill_radius:
			if can_kill_player:
				player_killed.emit()
				reset()
				return
		if player_guess_center.distance_to(origin) > stats.player_guess_reset_distance_threshold:
			player_guess_center = origin
			player_guess_radius = lerp(stats.player_guess_max_radius, 0.0, response)
			player_guess_velocity = Vector3.ZERO
		else:
			var implied_velocity: Vector3 = (origin - player_guess_center).normalized() * sound_implied_speed
			player_guess_velocity = lerp(player_guess_velocity, implied_velocity, response)
			player_guess_radius = lerp(player_guess_radius, 0.0, response)
			player_guess_center = lerp(player_guess_center, origin, response)
			player_guess_intensity = lerp(player_guess_intensity, 1.0, response)
		if player_guess_intensity > 0.1:
			select_player_hunt_target()
		# update_zones_at_position(player_guess_center, player_guess_zones)
		
	else: if(type == Sound.Type.EGG_NORMAL
	|| type == Sound.Type.EGG_GLASS
	|| type == Sound.Type.EXHIBIT_RECORDING):
		distraction_timer = 10.0 * response
		distraction_position = origin


###########
# SIGNALS #
###########

func _on_sound(origin: Vector3, type: Sound.Type):
	sound_queue.push_back(QueuedSound.new(origin, type))
	
func _on_set_stats(value: BunnyStats):
	stats = value

func _on_set_can_hunt_player(value: bool):
	can_hunt_player = value
	
func _on_set_can_kill_player(value: bool):
	can_kill_player = value

func _on_set_explore_zone_static(zones: Array[SearchZone]):
	explore_behavior = ExploreBehavior.ZONE_STATIC
	static_explore_zones = zones
	nav_goto_me()
	
func _on_set_explore_zone_follow_guess(initial_zones: Array[SearchZone]):
	explore_behavior = ExploreBehavior.ZONE_FOLLOW_GUESS
	static_explore_zones = initial_zones
	nav_goto_me()
	
func _on_set_explore_zone_follow_player():
	explore_behavior = ExploreBehavior.ZONE_FOLLOW_PLAYER
	nav_goto_me()
	
func _on_set_explore_radius_static(center: Vector3, radius: float):
	explore_behavior = ExploreBehavior.RADIUS_STATIC
	explore_point_center = center
	explore_point_radius = radius
	nav_goto_me()
	
func _on_set_explore_radius_follow_player(radius: float):
	explore_point_center = player.global_position
	explore_point_radius = radius
	nav_goto_me()

func _on_set_explore_patrol(path: Array[Node3D]):
	explore_behavior = ExploreBehavior.PATROL
	patrol_path = path
	current_patrol_node = 0
	nav_goto_target(patrol_path[current_patrol_node].global_position)
	
func _on_set_explore_stay_in_place(pos: Vector3):
	explore_behavior = ExploreBehavior.STAY_IN_PLACE
	explore_point_center = pos
	nav_goto_target(explore_point_center)
	
func _on_set_explore_always_hunt():
	explore_behavior = ExploreBehavior.ALWAYS_HUNT
	nav_goto_me()


#################
# BIG UTILITIES #
#################

func generate_explore_nodes_from_zone_at_position(pos: Vector3):
	static_explore_zones.clear()
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query = PhysicsPointQueryParameters3D.new()
	query.position = pos
	query.collide_with_areas = true 
	var results = space_state.intersect_point(query)
	for result in results:
		for zone in search_zones:
			if result["collider"] == zone.area:
				static_explore_zones.push_back(zone)
	generate_explore_nodes_from_zones(static_explore_zones)

func generate_explore_nodes_from_zones(zones: Array[SearchZone]):
	explore_node_indices.clear()
	for zone in zones:
		var zone_i: int = 0
		for i in search_nodes.size():
			if zone_i >= zone.search_nodes.size(): break
				
			var node: SearchNode = search_nodes[i]
			if node == zone.search_nodes[zone_i]:
				explore_node_indices.push_back(i)
				zone_i += 1

func generate_explore_nodes_from_point(center: Vector3, radius: float):
	explore_node_indices.clear()
	for i in search_nodes.size():
		if center.distance_to(search_nodes[i].global_position) <= radius:
			explore_node_indices.push_back(i)

func update_and_explore_nodes(dt: float):
	# Update node scores and get highest utility node.
	explore_node_indices.sort()
	var explore_i: int = 0
	var highest_utility: float = 0.0
	var highest_utility_node: SearchNode = search_nodes[explore_node_indices[0]]
	for search_i in search_nodes.size():
		var explore_node_index: int = -1
		if explore_i < explore_node_indices.size(): 
			explore_node_index = explore_node_indices[explore_i]
		
		var node: SearchNode = search_nodes[search_i]
		var distance: float
		if explore_node_index == search_i:
			distance = global_position.distance_to(node.global_position)
			explore_i += 1
		else:
			distance = 0.0

		var distance_contribution: float = lerp(-1.0, 1.0, clamp((distance / stats.exploration_distance_threshold) / 2.0, 0.0, 1.0))
		if distance_contribution > 0.0: distance_contribution *= stats.search_node_forget_rate
		if distance_contribution < 0.0: distance_contribution *= stats.search_node_explore_rate
		node.score += distance_contribution * dt

		var player_distance = player_guess_center.distance_to(node.global_position)
		var player_contribution: float = lerp(1.0, -1.0, clamp((player_distance / player_guess_radius) / 2.0, 0.0, 1.0))
		player_contribution *= 0.1 * player_guess_intensity
		node.score += player_contribution * dt

		if explore_node_index == search_i:
			if node.score / (distance * 0.2) > highest_utility:
				highest_utility = node.score
				highest_utility_node = node

	if explore_traverse_is_ready_for_target(dt):
		nav_goto_target(highest_utility_node.global_position)

# lmao naming things. Operates move/listen/think state machine, returning true 
# if another target is needed.
func explore_traverse_is_ready_for_target(dt: float) -> bool:
	match explore_state:
		ExploreState.MOVE:
			nav_set_traversal_speed()
			state_timer -= dt
			if state_timer < 0.0:
				nav_set_speed(0.0)
				state_timer = randf_range(stats.min_listen_seconds, stats.max_listen_seconds)
				explore_state = ExploreState.LISTEN
			if nav_at_target():
				nav_set_speed(0.0)
				state_timer = randf_range(stats.min_think_seconds, stats.max_think_seconds)
				explore_state = ExploreState.THINK
		ExploreState.LISTEN:
			state_timer -= dt
			if state_timer < 0.0:
				state_timer = randf_range(stats.min_move_seconds, stats.max_move_seconds)
				explore_state = ExploreState.MOVE
				return true
		ExploreState.THINK:
			state_timer -= dt
			if state_timer < 0.0:
				state_timer = randf_range(stats.min_move_seconds, stats.max_move_seconds)
				explore_state = ExploreState.MOVE
				return true
	return false

func select_player_hunt_target():
	var eligible_nodes: Array[SearchNode]
	for zone in player_guess_zones:
		for node in zone.nodes:
			if player_guess_center.distance_to(node.global_position) < player_guess_radius:
				eligible_nodes.push_back(node)
	if eligible_nodes.is_empty():
		player_hunt_target = player_guess_center
	else:
		player_hunt_target = eligible_nodes[randi_range(0, eligible_nodes.size() - 1)].global_position


##################
# SMOL UTILITIES #
##################

func nav_set_distance_attenuated_speed(distance_multiplier: float, min_speed: float, max_speed: float):
	nav_set_speed(clamp((global_position.distance_to(nav_target_position()) - 4.0) * distance_multiplier, min_speed, max_speed))
	
func nav_set_traversal_speed():
	nav_set_distance_attenuated_speed(stats.explore_speed_distance_multiplier, stats.min_explore_speed, stats.max_explore_speed)

func nav_set_speed(value: float):
	speed = value

func nav_goto_target(pos: Vector3):
	nav.target_position = pos

func nav_goto_me():
	nav_goto_target(global_position)

func nav_at_target() -> bool:
	return nav_target_delta().length() < nav_stop_distance

func nav_target_position() -> Vector3:
	return nav.get_final_position()

func nav_target_delta() -> Vector3:
	return nav_target_position() - global_transform.origin;

func nav_target_reachable() -> bool:
	return nav.is_target_reachable()
	
func nav_finished_but_not_reachable() -> bool:
	return nav.is_navigation_finished() && !nav_target_reachable()
