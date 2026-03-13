class_name EbBrainSmart extends EbBrain

enum State {
	ROAM_MOVE = 0,
	ROAM_LISTEN = 1,
	SEARCH = 2,
	INVESTIGATE = 3,
	HUNT = 4,
	STUNNED = 5
}

@export var path_nodes: Array[Node3D]
@export var acceleration: float = 20.0
@export var state: State = State.ROAM_MOVE
@export var death_radius: float = 6.0
@export var danger_radius: float = 12.0
@export var detection_radius: float = 24.0
@export var search_min_radius: float = 2.0
@export var search_max_radius: float = 4.0
@export var stun_min_timer: float = 4.0
@export var stun_max_timer: float = 8.0
@export var listen_hearing_distance_multiplier: float = 0.66
@export var distracted_hearing_distance_multiplier: float = 5.0

@export_group("State speeds")
@export var roam_speed: float = 3.0
@export var investigate_speed: float = 5.0
@export var search_speed: float = 5.0
@export var hunt_speed: float = 11.0

@export_group("State length ranges")
@export var roam_listen_min_seconds: float = 6.0
@export var roam_listen_max_seconds: float = 12.0
@export var roam_move_min_seconds: float = 6.0
@export var roam_move_max_seconds: float = 8.0
@export var search_min_seconds: float = 8.0
@export var search_max_seconds: float = 16.0
@export var search_listen_min_seconds: float = 2.0
@export var search_listen_max_seconds: float = 5.0
@export var distracted_min_seconds: float = 5.0
@export var distracted_max_seconds: float = 10.0

var target: Vector3
var search_position_target: Vector3 = Vector3.ZERO
var roam_move_listen_timer: float = 0.0
var search_listen_timer: float = 0.0
var search_state_timer: float = 0.0
var stunned_timer: float = 0.0
var distracted_timer: float = 0.0

func take_action(core: EbCore, dt: float):
	match state:
		State.ROAM_MOVE: roam_move(core, dt)
		State.ROAM_LISTEN: roam_listen(core, dt)
		State.INVESTIGATE: investigate(core)
		State.SEARCH: search(core, dt)
		State.HUNT: hunt(core)
		State.STUNNED: stunned(core, dt)

func respond_to_sound(core: EbCore, origin: Vector3, type: Sound.Type):
	var distance: float = core.position().distance_to(origin)
	
	if type == Sound.Type.AIRHORN && distance < detection_radius:
		stunned_timer = randf_range(stun_min_timer, stun_max_timer)
		state = State.STUNNED
		return
		
	if state == State.ROAM_LISTEN || core.velocity().length() < 0.1:
		distance *= listen_hearing_distance_multiplier
		
	if(type == Sound.Type.EGG_NORMAL
	|| type == Sound.Type.EGG_GLASS
	|| type == Sound.Type.EXHIBIT_RECORDING) && distance < detection_radius:
		distracted_timer = randf_range(distracted_min_seconds, distracted_max_seconds)
		target = origin
		state = State.INVESTIGATE
		return
		
	if distracted_timer > 0.0:
		distance *= distracted_hearing_distance_multiplier
	
	var new_state: State = state
	if distance < death_radius:
		if(type == Sound.Type.BREATH
		|| type == Sound.Type.CROUCH_FOOTSTEP
		|| type == Sound.Type.WALK_FOOTSTEP
		|| type == Sound.Type.RUN_FOOTSTEP):
			# TODO(conner): Kill the player
			print("The player is being killed, trust me!")
			new_state = State.HUNT
			core.kill_player()
	else: if distance < danger_radius:
		if(type == Sound.Type.WALK_FOOTSTEP
		|| type == Sound.Type.RUN_FOOTSTEP):
			new_state = State.HUNT
	else: if distance < (danger_radius + detection_radius) / 2.0:
		if type == Sound.Type.WALK_FOOTSTEP:
			new_state = State.INVESTIGATE
	else: if distance < detection_radius:
		if(type == Sound.Type.RUN_FOOTSTEP):
			new_state = State.INVESTIGATE
			
	if state as int < new_state as int:
		if new_state == State.ROAM_LISTEN:
			roam_move_listen_timer = randf_range(roam_listen_min_seconds, roam_listen_max_seconds)
		if new_state == State.INVESTIGATE:
			target = origin
		state = new_state

func roam_move(core: EbCore, dt: float):
	if core.nav_at_target():
		core.path_increment_waypoint()
	core.nav_goto_target(core.path_current_waypoint_position())
	core.nav_set_speed(2.0)
	roam_move_listen_timer -= dt
	if roam_move_listen_timer < 0.0:
		roam_move_listen_timer = randf_range(roam_listen_min_seconds, roam_listen_max_seconds)
		state = State.ROAM_LISTEN
	
func roam_listen(core: EbCore, dt: float):
	core.nav_goto_me()
	core.nav_set_speed(0.0)
	roam_move_listen_timer -= dt
	if roam_move_listen_timer < 0.0:
		roam_move_listen_timer = randf_range(roam_move_min_seconds, roam_move_max_seconds)
		state = State.ROAM_MOVE
		
func investigate(core: EbCore):
	core.nav_set_speed(investigate_speed)
	core.nav_goto_target(target)
	if !core.nav_target_reachable():
		# TODO(conner): Handle can't reach player while investigating
		pass
	if core.nav_at_target():
		search_state_timer = randf_range(search_min_seconds, search_max_seconds)
		search_listen_timer = randf_range(search_listen_min_seconds, search_listen_max_seconds)
		state = State.SEARCH

func search(core: EbCore, dt: float):
	core.nav_set_speed(2.0)	
	if distracted_timer > 0.0:
		search_state_timer = 1000.0
		distracted_timer -= dt
		if distracted_timer < 0.0:
			search_state_timer = 0.0
	search_state_timer -= dt
	if search_state_timer < 0.0:
		roam_move_listen_timer = randf_range(roam_move_min_seconds, roam_move_max_seconds)
		state = State.ROAM_MOVE
	if core.nav_at_target():
		core.nav_set_speed(0.0)
		search_listen_timer -= dt
		if search_listen_timer < 0.0:
			search_position_target = core.find_search_radius_position(search_min_radius, search_max_radius)
			core.nav_goto_target(search_position_target)
			search_listen_timer = randf_range(search_listen_min_seconds, search_listen_max_seconds)

func hunt(core: EbCore):
	core.nav_set_speed(5.0)
	core.nav_goto_target(core.player().position)
	if core.nav_finished_but_not_reachable():
		target = core.position()
		core.nav_goto_target(target)
		search_state_timer = randf_range(search_min_seconds, search_max_seconds)
		search_listen_timer = randf_range(search_listen_min_seconds, search_listen_max_seconds)
		state = State.SEARCH
	
func stunned(core: EbCore, dt: float):
	core.nav_set_speed(0.0)
	core.nav_goto_me()
	stunned_timer -= dt
	if stunned_timer < 0.0:
		state = State.HUNT

''' LOGIC FOR COMBINING/AGGREGATING NEARBY SOUNDS, CURRENTLY UNUSED.
	var closest_point_index: int = -1
	var closest_point_distance: float
	for i in points_of_interest.size():
		var point_distance: float = my_position.distance_to(points_of_interest[i].position)
		if closest_point_index == -1:
			closest_point_index = i
			closest_point_distance = point_distance
			continue
		if point_distance < closest_point_distance:
			closest_point_index = i
			closest_point_distance = point_distance
	if closest_point_index != -1 && closest_point_distance < sound_combine_distance:
		points_of_interest[closest_point_index].position = origin
		points_of_interest[closest_point_index].score = sound.interest_score
	else:
		points_of_interest.push_back(PointOfInterest.new(origin, sound.interest_score))
	'''
