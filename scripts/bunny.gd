class_name Bunny extends CharacterBody3D

class QueuedSound:
	var origin: Vector3
	var type: Sound.Type
	func _init(org: Vector3, typ: Sound.Type):
		origin = org
		type = typ

enum ExploreState {
	MOVE,
	LISTEN,
	THINK
}

signal player_killed()

@export_group("External References")
## This property should be set up to reference the SearchZoneParent node.[br][br]
## The [SearchZone] nodes used by EB to explore and pathfind are assumed to be 
## set up as children of a single parent node and as parents of multiple 
## [SearchNode] nodes, with the hierarchical structure being as follows:[br][br]
## [center][b]SearchZonesParent[/b] -> [SearchZone] -> [SearchNode].[/center][br][br]
@export var search_zones_parent: Node3D
@export_group("Initialization")
## If this is set to [b]true[/b], debug visualizers will be made active. If not,
## the associated nodes will be deleted on game start.
@export var use_debug_info: bool = true
## If this is set to [b]false[/b], situations which would normally kill the 
## player will not. Useful for testing functionality without interruption.
@export var can_kill_player: bool = true
## The [SearchZone] nodes in this array define the set of nodes which EB will 
## try to explore when he isn't in another state such as following the player or
## being distracted.
## [br][br]If using multiple zones, they should probably all be adjacent, 
## otherwise poor EB is going to have a hard time going back and forth trying to
## explore.
## [br][br]This currently hooks some things up in the background at game start,
## but we are going to deprecate this very soon to allow for setting new explore
## zones at runtime.
## @experimental
@export var initial_explore_zones: Array[SearchZone]
@export_group("Locomotion")
## Determines the distance from the target node that the pathfinding system will
## consider as having arrived. This should be set low, but not too low.
## Something like [b]0.1[/b] seems fine.
@export var nav_stop_distance: float = 0.1
## Determines how quickly EB changes his velocity when stopping, starting, or
## changing direction.
@export var acceleration: float = 20.0
@export_group("Exploration")
## As EB moves between [SearchNode] nodes, he modifies its 
## [member SearchNode.score] value, which represents how much EB wants to 
## explore that particular node.
## [br][br]For every node, if he is closer than this exploration distance 
## threshold, he lowers the score. If he is farther, he raises it. The amount 
## that it changes is directly proportional to how far the distance is from this
## threshold.
@export var exploration_distance_threshold: float = 10.0
## This is related to the [member exploration_distance_threshold]. If the 
## distance to a node is higher than the threshold, the amount that the score 
## raises is modulated by this value. He will "forget" about the node quicker 
## the higher this number is, and slower the lower it is.
@export var search_node_forget_speed: float = 0.1
## This is related to the [member exploration_distance_threshold]. If the 
## distance to a node is lower than the threshold, the amount that the score 
## lowers is modulated by this value. He will explore the node quicker the 
## higher this number is, and slower the lower it is.
@export var search_node_explore_speed: float = 0.5
@export_group("Hunting")
## When EB has a guess as to the player's whereabouts, it is bounded by a
## certain radius. EB assumes the player might be somewhere inside this radius.
## Over time when EB isn't hearing any sounds, the radius passively grows, and
## [member player_guess_max_radius] is the maximum size it grows toward.
@export var player_guess_max_radius: float = 14.0
## Determines the rate at which EB's player search radius grows. See [member
## player_guess_max_radius] documentation for an explanation of the radius.
@export var player_guess_radius_expansion_rate: float = 2.0
## As EB hears successive sounds by the player, he integrates them together and,
## inferring things like the player's possible velocity by comparing the 
## difference in positions of recent sounds, and slowly converging towards a
## more accurate picture the more sounds he hears. 
## [br][br]However, if a sound he hears is further away from the last heard 
## sound than [member player_guess_reset_distance_threshold], the radius and 
## velocity guesses are reset, because the sound is far enough away that he 
## isn't sure how to integrate them anymore.
@export var player_guess_reset_distance_threshold: float = 12.0
## As EB tries to integrate the sounds he hears, one of the variables he tracks
## is a guess about the player's current direction and speed. He uses that 
## guessed velocity to move his search radius in that direction over time.
## [br][br][member player_guess_velocity_depreciation_rate] sets how quickly 
## this speed slows down over time, as EB can't be sure the player is still 
## moving in the same direction, and if he isn't hearing any more sounds, it is 
## probably a good idea for him to assume the player might have stopped.
@export var player_guess_velocity_depreciation_rate: float = 0.004
## Hearing sounds causes the "intensity" of EB's guess about the player to rise,
## and the intensity rising above a certain level is what triggers EB to start
## actively hunting for the player. 
## [br][br][member player_guess_intensity_depreciation_rate] sets how quickly
## this intensity lowers over time, which eventually causes EB to lose interest
## in the hunt and go back to exploring.
@export var player_guess_intensity_depreciation_rate: float = 0.01
## When EB hears a sound through a wall, his ability to hear it is is attenuated
## by [member sound_wall_obstruction_modifier]. This is done by dividing the 
## apparent distance to the sound by this value. This means lower numbers mean
## a worse ability to hear, higher numbers means better hearing.
@export var sound_wall_obstruction_modifier: float = 0.25
## This works the same way as [member sound_wall_obstruction_modifier], but when
## the sound is heard through an obstacle rather than a wall, when the player is
## crouching behind a cabinet, for instance. It should be a higher number than
## the wall variant, as walls are probably worse for hearing than obstacles.
@export var sound_obstacle_obstruction_modifier: float = 0.5
## Breath and player footsteps heard within this radius result in a player 
## death, assuming [member can_kill_player] is true. Right now, death is a signal
## picked up by the Director node to reset the positions of EB and the player,
## and EB also does some resetting of his own state. We will want to discuss how
## we want player death to work in the final game.
@export var player_kill_radius: float = 3.0
@export_group("Speed")
## The speed at which EB moves when exploring is equal to ([member 
## explore_speed_distance_multiplier] * distance to target), and then the result
## is clamped between [member min_explore_speed] and [member max_explore_speed].
## [br][br]The effect is that EB moves quicker to get to nodes he is further 
## away from.
@export var explore_speed_distance_multiplier: float = 1.0
## The minimum speed for moving towards a target node while exploring. Ensures
## that the speed doesn't go below this value after calculating the speed from
## [member explore_speed_distance_multiplier].
@export var min_explore_speed: float = 3.0
## The maximum speed for moving towards a target node while exploring. Ensures
## that the speed doesn't go above this value after calculating the speed from
## [member explore_speed_distance_multiplier].
@export var max_explore_speed: float = 6.0
## See [member explore_speed_distance_multiplier]. This works exactly the same
## way, but while hunting for the player.
@export var hunt_speed_distance_multiplier: float = 1.0
## See [member min_explore_speed]. This works exactly the same way, but while 
## hunting for the player.
@export var min_hunt_speed: float = 2.0
## See [member max_explore_speed]. This works exactly the same way, but while 
## hunting for the player.
@export var max_hunt_speed: float = 8.0
## See [member explore_speed_distance_multiplier]. This works exactly the same
## way, but while distracted, by an egg for instance.
@export var distracted_speed_distance_multiplier: float = 1.0
## See [member min_explore_speed]. This works exactly the same way, but while 
## distracted, by an egg for instance.
@export var min_distracted_speed: float = 3.0
## See [member max_explore_speed]. This works exactly the same way, but while 
## distracted, by an egg for instance.
@export var max_distracted_speed: float = 8.0
@export_group("State lengths")
## Determines the minimum amount of seconds that the player should move while
## exploring before stopping to listen.
## [br][br]Truth be told, after playing with it for a bit, I'm not sure I like
## the random stops to listen. EB already sometimes stops when he reaches target
## nodes, and the extra stops to listen just make it easier for the player to 
## exploit his movement. I don't know, though, so I'm keeping it in for now.
@export var min_move_seconds: float = 4.0
## Determines the maximum amount of seconds that the player should move while
## exploring before stopping to listen. See [member min_move_seconds].
@export var max_move_seconds: float = 8.0
## After moving for some number of seconds while exploring, EB will randomly
## stop to listen, and this is the minimum amount of seconds he will do so for. 
## [br][br]As mentioned in the documentation for [member min_move_seconds], I'm 
## not sure I like this behavior, but it's still here for now.
@export var min_listen_seconds: float = 2.0
## The maximum amount of seconds EB will listen for after randomly stopping 
## during exploration.
@export var max_listen_seconds: float = 3.0
## When EB reaches a search node during explanation, he will think for a random
## number of seconds before moving to the next search node. This is the minimum
## seconds for that. I have it set here to a negative value, which ends up 
## giving him a chance of not stopping at all, or more specifically, of immediately
## returning to the move state after stopping to think. 
## [br][br]Given that the time selected is in a random range, the current min 
## and max values I have currently set (-1.0 to 2.0) will give a 1 in 3 chance
## that EB immediately starts moving again.
@export var min_think_seconds: float = -1.0
## This is the maximum value for- oh jeez just read [member min_think_seconds].
@export var max_think_seconds: float = 2.0
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

@onready var pivot: Node3D = $Pivot
@onready var nav: NavigationAgent3D = $NavAgent

var speed: float = 0.0
var sound_queue: Array[QueuedSound]
# Exploration state
var explore_state: ExploreState = ExploreState.LISTEN
var search_zones: Array[SearchZone]
var search_nodes: Array[SearchNode]
var explore_nodes: Array[SearchNode]
var state_timer: float = 0.0
# Hunting state
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

func _ready():
	# Listen for sound emitting nodes. They all have to exist at game start
	var sound_emitters = get_tree().get_nodes_in_group("SoundEmitters")
	for emitter in sound_emitters:
		emitter.sound.connect(on_sound)

	# Populate search and explore zones
	# TODO(conner): Move explore zone stuff so we can set them at runtime
	var tmp_zones = search_zones_parent.get_children()
	for zone in tmp_zones:
		if zone is SearchZone:
			search_zones.push_back(zone as SearchZone)
		var is_explore_zone: bool
		for ezone in initial_explore_zones:
			if zone == ezone: is_explore_zone = true
		var nodes: Array[Node] = zone.get_children()
		for node in nodes:
			if node is SearchNode:
				if is_explore_zone:
					explore_nodes.push_back(node)
				search_nodes.push_back(node)

	# Initialize state
	reset()

func _process(dt: float):
	var search_node: SearchNode = update_explore_nodes(dt)
	
	stun_timer -= dt
	if stun_timer > 0.0:
		nav_goto_me()
		nav_set_speed(0.0)
		return
	
	# Are we distracted?
	if distraction_timer > 0.0:
		nav_goto_target(distraction_position)
		nav_set_speed(clamp((global_position.distance_to(nav.get_final_position()) - 4.0) * distracted_speed_distance_multiplier, min_distracted_speed, max_distracted_speed))
		if global_position.distance_to(distraction_position) < 6.0:
			distraction_timer -= dt
		return
	
	# If we aren't distracted, do we have a guess of the player's whereabouts?
	if player_guess_intensity > 0.2:
		nav_set_speed(clamp((global_position.distance_to(nav.get_final_position()) - 4.0) * hunt_speed_distance_multiplier, min_hunt_speed, max_hunt_speed))
		if nav_at_target():
			select_player_nav_target()
		return
	
	# If we don't have a guess, start exploring.
	match explore_state:
		ExploreState.MOVE:
			nav_set_speed(clamp((global_position.distance_to(nav_target_position()) - 4.0) * explore_speed_distance_multiplier, min_explore_speed, max_explore_speed))
			state_timer -= dt
			if state_timer < 0.0:
				nav_set_speed(0.0)
				state_timer = randf_range(min_listen_seconds, max_listen_seconds)
				explore_state = ExploreState.LISTEN
			if nav_at_target():
				nav_set_speed(0.0)
				state_timer = randf_range(min_think_seconds, max_think_seconds)
				explore_state = ExploreState.THINK
		ExploreState.LISTEN:
			state_timer -= dt
			if state_timer < 0.0:
				nav_goto_target(search_node.global_position)
				state_timer = randf_range(min_move_seconds, max_move_seconds)
				explore_state = ExploreState.MOVE
		ExploreState.THINK:
			state_timer -= dt
			if state_timer < 0.0:
				nav_goto_target(search_node.global_position)
				state_timer = randf_range(min_move_seconds, max_move_seconds)
				explore_state = ExploreState.MOVE

func _physics_process(dt: float):
	for sound in sound_queue:
		process_sound(sound.origin, sound.type)
	sound_queue.clear()
	
	#player_guess_radius += clamp(player_guess_radius, 1.0, 8.0) * player_guess_radius_expansion_rate * dt
	player_guess_radius += player_guess_radius_expansion_rate * dt
	if player_guess_radius > player_guess_max_radius:
		player_guess_radius = player_guess_max_radius
	var distance_to_player_guess: float = global_position.distance_to(player_guess_center)
	if distance_to_player_guess < clamp(6.0, player_guess_radius, player_guess_radius):
		var intensity_distance_mod: float = 1.0 / clamp(0.1, distance_to_player_guess, distance_to_player_guess)
		player_guess_intensity = lerp(player_guess_intensity, 0.0, player_guess_intensity_depreciation_rate * intensity_distance_mod)
	# Move player guess
	player_guess_velocity = lerp(player_guess_velocity, Vector3.ZERO, player_guess_velocity_depreciation_rate)
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var ray_origin = Vector3(player_guess_center.x, 1.0, player_guess_center.z)
	var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + player_guess_velocity * dt * 2.0, 0b00000000_00000000_00000000_00000110)
	var result = space_state.intersect_ray(ray_query)
	if !result.is_empty():
		print("resetting the thing to 0!")
		player_guess_velocity = Vector3.ZERO
	player_guess_center += player_guess_velocity * dt
	update_player_guess_zone()
	
	var desired_velocity: Vector3 = Vector3.ZERO
	var target = nav.get_next_path_position()
	var delta: Vector3 = target - global_transform.origin;

	if(delta.length()) > nav_stop_distance:
		desired_velocity = delta.normalized() * speed
		pivot.rotation.y = atan2(desired_velocity.x, desired_velocity.z)
	else:
		# TODO(conner): global position?
		nav.target_position = position
	velocity = velocity.move_toward(desired_velocity, acceleration * dt)
	move_and_slide()
	
func process_sound(origin: Vector3, type: Sound.Type):
	var actual_distance: float = global_position.distance_to(origin) / 100.0
	var distance_score = actual_distance
	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var ray_start = Vector3(global_position.x, 4.0, global_position.z)
	var ray_end = Vector3(origin.x, 4.0, origin.z)
	var ray_query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, 0b00000000_00000000_00000000_00001110)
	var result = space_state.intersect_ray(ray_query)
	if !result.is_empty():
		print("obstructed by wall")
		distance_score *= 1.0 / sound_wall_obstruction_modifier
	else:
		print("not obstructed by wall")
	#else:
		#ray_start = Vector3(global_position.x, 1.0, global_position.z)
		#ray_end = Vector3(origin.x, 0.1, origin.y)
		#ray_query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, 0b00000000_00000000_00000000_00000000)
		#result = space_state.intersect_ray(ray_query)
		#if !result.is_empty():
			#print("obstructed by obstacle")
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
	
	if response <= 0.01:
		return
	
	#print("sound heard: ", type)
		
	if(type == Sound.Type.BREATH
	|| type == Sound.Type.CROUCH_FOOTSTEP
	|| type == Sound.Type.WALK_FOOTSTEP
	|| type == Sound.Type.RUN_FOOTSTEP):
		if global_position.distance_to(origin) < player_kill_radius:
			if can_kill_player:
				player_killed.emit()
				reset()
				return
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
			select_player_nav_target()
		update_player_guess_zone()
		
	else: if(type == Sound.Type.EGG_NORMAL
	|| type == Sound.Type.EGG_GLASS
	|| type == Sound.Type.EXHIBIT_RECORDING):
		distraction_timer = 10.0 * response
		distraction_position = origin
	else: if(type == Sound.Type.AIRHORN):
		stun_timer = 6.0

func on_sound(origin: Vector3, type: Sound.Type):
	sound_queue.push_back(QueuedSound.new(origin, type))
		
func update_player_guess_zone():
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	player_guess_zones.clear()
	var query = PhysicsPointQueryParameters3D.new()
	query.position = player_guess_center
	query.collide_with_areas = true 
	var results = space_state.intersect_point(query)
	for res in results:
		for zone in search_zones:
			if res["collider"] == zone.area:
				player_guess_zones.push_back(zone)

func update_explore_nodes(dt: float) -> SearchNode:
	for node in explore_nodes:
		var distance = global_position.distance_to(node.global_position)
		var distance_contribution: float = lerp(-1.0, 1.0, clamp((distance / exploration_distance_threshold) / 2.0, 0.0, 1.0))
		if distance_contribution > 0.0: distance_contribution *= search_node_forget_speed
		if distance_contribution < 0.0: distance_contribution *= search_node_explore_speed
		node.score += distance_contribution * dt
		
		var player_distance = player_guess_center.distance_to(node.global_position)
		var player_contribution: float = lerp(1.0, -1.0, clamp((player_distance / player_guess_radius) / 2.0, 0.0, 1.0))
		player_contribution *= 0.1 * player_guess_intensity
		node.score += player_contribution * dt
	var highest_utility: float = 0.0
	var highest_utility_node: SearchNode = explore_nodes[0]
	for node in explore_nodes:
		var distance = global_position.distance_to(node.global_position)
		if node.score / (distance * 0.2) > highest_utility:
			highest_utility = node.score
			highest_utility_node = node
	return highest_utility_node

func select_player_nav_target():
	var eligible_nodes: Array[SearchNode]
	for zone in player_guess_zones:
		for node in zone.nodes:
			if player_guess_center.distance_to(node.position) < player_guess_radius:
				eligible_nodes.push_back(node)
	if eligible_nodes.is_empty():
		#print("NO ELIGIBLE NODES!")
		nav_goto_target(player_guess_center)
	else:
		nav_goto_target(eligible_nodes[randi_range(0, eligible_nodes.size() - 1)].position)

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
