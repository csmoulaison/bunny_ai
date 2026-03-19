class_name Bunny extends CharacterBody3D
## The bunny, the bunny, Ooh I love the bunny.
##
## I need to do more of a high level description of the bunny here, but I 
## thought it would be important to at least list out all of the signals that
## EB responds to and what their function signatures are. If you want EB to
## respond to a signal, the node emitting it must be part of the 
## "EbEventEmitter" group and the signal must have the same signature and name
## as one of the below options:[br]
## [br][b]eb_sound[/b](origin: Vector3, type: Sound.Type)
## [br][b]eb_set_explore_behavior[/b](zones: Array[lb]SearchZone[rb])
## [br][b]eb_set_guard_behavior[/b](node: SearchNode, nearby_max_distance: float)
## [br][b]eb_set_patrol_behavior[/b](path: Array[lb]SearchNode[rb])
## [br][b]eb_set_hunt_behavior[/b](behavior: HuntBehavior)
## [br][b]eb_set_can_kill_player[/b](value: bool)
## [br][br]I'll document these a little better later, but for now, programmers, 
## let me know if you have any questions for how these work. Also let me know if
## we want to do other things at runtime other than these. I suspect we might
## want to be able to tweak values like the speed, player guess properties, and
## stuff like that, but it would be best if these were done through signals
## rather than reaching directly into EB's state, as my assumptions about EB's
## state throughout this logic would be preserved in that case.

class QueuedSound:
	var origin: Vector3
	var type: Sound.Type
	func _init(org: Vector3, typ: Sound.Type):
		origin = org
		type = typ

# TODO(conner): Document these options.
enum ExploreBehavior {
	ZONE_STATIC,
	ZONE_FOLLOW_GUESS,
	ZONE_FOLLOW_PLAYER,
	ZONE_PREDICT_PLAYER,
	RADIUS_STATIC,
	RADIUS_FOLLOW_PLAYER,
	PATROL,
	ALWAYS_HUNT,
	STAY_IN_PLACE
}

enum HuntBehavior {
	## EB will hunt the player if he hears enough relevant sounds.
	HUNT,
	## EB will not hunt the player, but his player guessing logic still 
	## continues to run.
	IGNORE
}

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
@export_group("High level behavior")
## Determines the default set of behaviors that EB follows when he is not either
## currently hunting the player, distracted, or stunned.
@export var explore_behavior: ExploreBehavior = ExploreBehavior.ZONE_STATIC
## You can turn off EB's ability to hunt the player by setting this to 
## [b]Ignore[/b].
@export var hunt_behavior: HuntBehavior = HuntBehavior.HUNT
## If this is set to [b]false[/b], situations which would normally kill the 
## player will not. Useful for testing functionality without interruption.
@export var can_kill_player: bool = true
## If this is set to [b]true[/b], debug visualizers will be made active. If not,
## the associated nodes will be deleted on game start.
@export var use_debug_info: bool = true
@export_group("Explore: Zone")
## The [SearchZone] nodes in this array define the set of nodes which EB will 
## try to explore when he isn't in another state such as following the player or
## being distracted.
## [br][br]If using multiple zones, they should probably all be adjacent, 
## otherwise poor EB is going to have a hard time going back and forth trying to
## explore.
@export var static_explore_zones: Array[SearchZone]
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
@export var search_node_forget_rate: float = 0.1
## This is related to the [member exploration_distance_threshold]. If the 
## distance to a node is lower than the threshold, the amount that the score 
## lowers is modulated by this value. He will explore the node quicker the 
## higher this number is, and slower the lower it is.
@export var search_node_explore_rate: float = 0.5
@export_group("Explore: Radius")
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
## NOTE: This is not actually in place yet, the wall functions for both.
## [br][br]This works the same way as [member sound_wall_obstruction_modifier], but when
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
@export_group("Guard")
## If using the guard node idle behavior, EB will guard this node and nodes that
## are nearby.
@export var guard_node: SearchNode
## Determines how close a node needs to be to [member guard_node] in order to be
## part of the random selection of nodes searched by EB 
@export var guard_nearby_max_distance: float = 6.0
@export_group("Patrol")
## If using the patrol path cycle idle behavior, EB will patrol between the 
## nodes in this array cyclically
@export var patrol_path: Array[SearchNode]
@export_group("Speeds")
## The speed at which EB moves when doing the current goal behavior is equal to 
## ([member explore_speed_distance_multiplier] * distance to target), and then 
## the result is clamped between [member min_explore_speed] and 
## [member max_explore_speed].
## [br][br]The effect is that EB moves quicker to get to nodes he is further 
## away from.
@export var explore_speed_distance_multiplier: float = 1.0
## The minimum speed for moving towards a target node while doing the current 
## explore behavior. Ensures that the speed doesn't go below this value 
## after calculating the speed from [member explore_speed_distance_multiplier].
@export var min_explore_speed: float = 3.0
## The maximum speed for moving towards a target node while doing the current
## explore behavior. Ensures that the speed doesn't go above this value after 
## calculating the speed from [member idle_speed_distance_multiplier].
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
@export var min_think_seconds: float = 0.0
## This is the maximum value for- oh jeez just read [member min_think_seconds].
@export var max_think_seconds: float = 3.0
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
@export var airhorn_response_curve: SoundCurve # TODO(conner): airhorn as radius, response as stun length.
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
#var explore_nodes: Array[SearchNode]
var state_timer: float = 0.0
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
		ExploreBehavior.ZONE_PREDICT_PLAYER:
			_on_set_explore_zone_predict_player()
		# TODO(conner): 
		ExploreBehavior.RADIUS_STATIC:
			_on_set_explore_radius_static(x, x)
		ExploreBehavior.RADIUS_FOLLOW_PLAYER:
			_on_set_explore_radius_follow_player(radiussss)
		ExploreBehavior.PATROL:
			_on_set_explore_patrol(patrol_path)
		ExploreBehavior.STAY_IN_PLACE:
			_on_set_explore_stay_in_place(poossisition)
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
			if signal_dictionary.name == "eb_set_explore_zone_predict_player":
				emitter.eb_set_explore_zone_predict_player.connect(_on_set_explore_zone_predict_player)
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

	# Populate search and explore zones
	var tmp_zones = search_zones_parent.get_children()
	for zone in tmp_zones:
		if zone is SearchZone:
			search_zones.push_back(zone as SearchZone)
		var nodes: Array[Node] = zone.get_children()
		for node in nodes:
			if node is SearchNode:
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
		nav_set_distance_attenuated_speed(distracted_speed_distance_multiplier, min_distracted_speed, max_distracted_speed)
		if global_position.distance_to(distraction_position) < 6.0:
			distraction_timer -= dt
		return
		
	# Do we have a guess of the player's whereabouts?
	if hunt_behavior == HuntBehavior.HUNT && player_guess_intensity > 0.2:
		nav_set_distance_attenuated_speed(hunt_speed_distance_multiplier, min_hunt_speed, max_hunt_speed)
		if nav_at_target():
			select_player_hunt_target()
		nav_goto_target(player_hunt_target)
		return
	
	# If we aren't distracted, follow our explore behavior.
	# TODO(conner): implement explore behaviors
	match explore_behavior:
		ExploreBehavior.ZONE_STATIC:
			explore_zone_static(dt)
		ExploreBehavior.ZONE_FOLLOW_GUESS:
			explore_zone_follow_guess(dt)
		ExploreBehavior.ZONE_FOLLOW_PLAYER:
			explore_zone_follow_player(dt)
		ExploreBehavior.ZONE_PREDICT_PLAYER:
			explore_zone_predict_player(dt)
		ExploreBehavior.RADIUS_STATIC:
			explore_radius_static(dt)
		ExploreBehavior.RADIUS_FOLLOW_PLAYER:
			explore_radius_follow_player(dt)
		ExploreBehavior.PATROL:
			explore_patrol(dt)
		ExploreBehavior.ALWAYS_HUNT:
			explore_always_hunt(dt)
		ExploreBehavior.STAY_IN_PLACE:
			explore_stay_in_place(dt)

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
		player_guess_velocity = Vector3.ZERO
	player_guess_center += player_guess_velocity * dt
	update_zones_at_position(player_guess_center, player_guess_zones)
	
	var desired_velocity: Vector3 = Vector3.ZERO
	var target = nav.get_next_path_position()
	var delta: Vector3 = target - global_transform.origin;

	if delta.length() > nav_stop_distance:
		desired_velocity = delta.normalized() * speed
		pivot.rotation.y = atan2(desired_velocity.x, desired_velocity.z)
	else:
		# TODO(conner): global position?
		nav.target_position = global_position
	velocity = velocity.move_toward(desired_velocity, acceleration * dt)
	move_and_slide()

func process_sound(origin: Vector3, type: Sound.Type):
	var actual_distance: float = global_position.distance_to(origin) / 100.0
	var distance_score = actual_distance
	
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
			distance_score /= sound_wall_obstruction_modifier
		else:
			ray_query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, 0b00000000_00000000_00000000_00000100)
			result = space_state.intersect_ray(ray_query)
			if !result.is_empty():
				print("  Obstructed by obstacle.")
				distance_score /= sound_obstacle_obstruction_modifier
	
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
			select_player_hunt_target()
		update_zones_at_position(player_guess_center, player_guess_zones)
		
	else: if(type == Sound.Type.EGG_NORMAL
	|| type == Sound.Type.EGG_GLASS
	|| type == Sound.Type.EXHIBIT_RECORDING):
		distraction_timer = 10.0 * response
		distraction_position = origin
	else: if(type == Sound.Type.AIRHORN):
		stun_timer = 6.0


###########
# SIGNALS #
###########

func _on_sound(origin: Vector3, type: Sound.Type):
	sound_queue.push_back(QueuedSound.new(origin, type))

func _on_set_can_hunt_player(behavior: HuntBehavior):
	hunt_behavior = behavior
	
func _on_set_can_kill_player(value: bool):
	can_kill_player = value

func _on_set_explore_zone_static(zones: Array[SearchZone]):
	explore_behavior = ExploreBehavior.ZONE_STATIC
	static_explore_zones = zones
	
func _on_set_explore_zone_follow_guess(initial_zones: Array[SearchZone]):
	explore_behavior = ExploreBehavior.ZONE_FOLLOW_GUESS
	static_explore_zones = initial_zones
	# TODO(conner): Set zone to guess zone IF the guess zone is active.
	
func _on_set_explore_zone_follow_player():
	explore_behavior = ExploreBehavior.ZONE_FOLLOW_PLAYER
	# TODO(conner): Set zone to the player zone.
	
func _on_set_explore_zone_predict_player():
	explore_behavior = ExploreBehavior.ZONE_PREDICT_PLAYER
	# TODO(conner): Set zone to prediction
	
func _on_set_explore_radius_static(center: Vector3, radius: float):
	explore_behavior = ExploreBehavior.RADIUS_STATIC
	explore_point_center = center
	explore_point_radius = radius
	
func _on_set_explore_radius_follow_player(radius: float):
	explore_point_center = player.global_position
	explore_point_radius = radius

func _on_set_explore_patrol(path: Array[SearchNode]):
	explore_behavior = ExploreBehavior.PATROL
	patrol_path = path
	
func _on_set_explore_stay_in_place(pos: Vector3):
	explore_behavior = ExploreBehavior.STAY_IN_PLACE
	explore_point_center = pos
	
func _on_set_explore_always_hunt():
	explore_behavior = ExploreBehavior.ALWAYS_HUNT


#####################
# EXPLORE BEHAVIORS #
#####################

# TODO(conner): All of these behaviors are very similar, and factoring them 
# should be quite easy. I just don't want to do it right now. Doing it later
# might be worth it, though.

# TODO(conner): implement all the exploration behaviors. It will involve pre-
# computing all the search nodes as indices in a PackedInt32Array, ideally, and 
# then exploring within those nodes. 
# What is the commonality point here? Is computing the search nodes the common
# functionality? Probably not to the extent that it can exist in the outer loop,
# but perhaps to the extent that the inner implementations become mostly small
# functions that call out to shared utilities. 

func idle_explore_update(dt: float):
	var search_node: SearchNode = update_explore_nodes(dt)
	match explore_state:
		ExploreState.MOVE:
			nav_set_traversal_speed()
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
	#if explore_behavior == ExploreZoneBehavior.MATCH_PLAYER_GUESS || explore_behavior == ExploreZoneBehavior.MATCH_PLAYER_ACTUAL:
	var target_explore_zones: Array[SearchZone]
	var should_update_explore_zones: bool = true
	match explore_behavior:
		ExploreZoneBehavior.STATIC: should_update_explore_zones = false
		ExploreZoneBehavior.MATCH_PLAYER_GUESS: target_explore_zones = player_guess_zones
		ExploreZoneBehavior.MATCH_PLAYER_ACTUAL: update_zones_at_position(player.global_position, target_explore_zones)
	if should_update_explore_zones && target_explore_zones != explore_zones:
		_on_set_explore_behavior(target_explore_zones, explore_behavior)

func idle_guard_node_update(dt: float):
	match explore_state:
		ExploreState.MOVE:
			nav_set_traversal_speed()
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
				nav_goto_target(nearby_guard_nodes[randi_range(0, nearby_guard_nodes.size() - 1)].global_position)
				state_timer = randf_range(min_move_seconds, max_move_seconds)
				explore_state = ExploreState.MOVE
		ExploreState.THINK:
			state_timer -= dt
			if state_timer < 0.0:
				nav_goto_target(nearby_guard_nodes[randi_range(0, nearby_guard_nodes.size() - 1)].global_position)
				state_timer = randf_range(min_move_seconds, max_move_seconds)
				explore_state = ExploreState.MOVE

func idle_patrol_node_cycle_update(dt: float):
	match explore_state:
		ExploreState.MOVE:
			nav_goto_target(patrol_path[current_patrol_node].global_position)
			nav_set_traversal_speed()
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
				state_timer = randf_range(min_move_seconds, max_move_seconds)
				explore_state = ExploreState.MOVE
		ExploreState.THINK:
			state_timer -= dt
			if state_timer < 0.0:
				current_patrol_node += 1
				if current_patrol_node >= patrol_path.size(): current_patrol_node = 0
				state_timer = randf_range(min_move_seconds, max_move_seconds)
				explore_state = ExploreState.MOVE


#################
# BIG UTILITIES #
#################

func update_zones_at_position(pos: Vector3, zones: Array[SearchZone]):
	zones.clear()
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query = PhysicsPointQueryParameters3D.new()
	query.position = pos
	query.collide_with_areas = true 
	var results = space_state.intersect_point(query)
	for res in results:
		for zone in search_zones:
			if res["collider"] == zone.area:
				zones.push_back(zone)

func update_explore_nodes(dt: float) -> SearchNode:
	for node in explore_nodes:
		var distance = global_position.distance_to(node.global_position)
		var distance_contribution: float = lerp(-1.0, 1.0, clamp((distance / exploration_distance_threshold) / 2.0, 0.0, 1.0))
		if distance_contribution > 0.0: distance_contribution *= search_node_forget_rate
		if distance_contribution < 0.0: distance_contribution *= search_node_explore_rate
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


####################
# LITTLE UTILITIES #
####################

func nav_set_distance_attenuated_speed(distance_multiplier: float, min_speed: float, max_speed: float):
	nav_set_speed(clamp((global_position.distance_to(nav_target_position()) - 4.0) * distance_multiplier, min_speed, max_speed))
	
func nav_set_traversal_speed():
	nav_set_distance_attenuated_speed(explore_speed_distance_multiplier, min_explore_speed, max_explore_speed)

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
