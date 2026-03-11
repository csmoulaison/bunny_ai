# NOTE(conner): The brain reponds to sounds and updates a series of values which
# are used to drive logic in the other modules. Values like suspicion act both
# as modifiers to behavior and as countdown timers controlling regression to
# "lower" states.
#
# We also want to be able to replace this brain with alternates that expose the
# same interface. The interface never changes, which means any concept that the
# interface references directly should be locked in quickly and be invariant
# between the different brain designs. It's important that we are able to plug
# in different brains so that we can pull back from this wacko design if wanted.

# NOTE(conner): Implementation questions:
# - Can EB still hear while he is stunned?
class_name EbBrain extends Node

enum Action {
	ROAM,
	LISTEN,
	SEARCH,
	HUNT,
	STUNNED
}

class PointOfInterest:
	var position: Vector3
	var interest: float
	var confidence: float
	func _init(pos: Vector3, intrst: float):
		position = pos
		interest = intrst
		confidence = 2.0

@export var speed_mod: float = 1.0
@export var player_kill_radius: float = 4.0
@export var sound_combine_distance: float = 5.0
@export var hunt_interest_threshold: float = 7.5
@export var listen_interest_threshold: float = 4.0
@export var confidence_timer_radius: float = 3.0
@export var search_min_radius: float = 2.5
@export var search_max_radius: float = 5.0
@export_group("Sound Response Configuration")
@export var breath_interest_curve: SoundCurve = SoundCurve.new()
@export var crouch_interest_curve: SoundCurve = SoundCurve.new()
@export var walk_interest_curve: SoundCurve = SoundCurve.new()
@export var run_interest_curve: SoundCurve = SoundCurve.new()
@export var egg_interest_curve: SoundCurve = SoundCurve.new()
@export var glass_interest_curve: SoundCurve = SoundCurve.new()
@export var exhibit_interest_curve: SoundCurve = SoundCurve.new()
@export var airhorn_stun_curve: SoundCurve = SoundCurve.new()

var previous_action: Action
var alertness: float = 0.0
var stun: float = 0.0
var points_of_interest: Array[PointOfInterest]
var target: Vector3 = Vector3.ZERO
var search_position_target: Vector3 = Vector3.ZERO
var search_position_timer: float = 0.0

func take_action(core: EbCore, dt: float):
	# TODO(conner): I'm thinking to add unpredictability to the timing of these
	# meters, we create a global countdown with a large (0.5 seconds, 2 seconds)
	# time span. Each countdown trigger, we set a random speed for these values
	# (anxiety, suspicion, etc) counting down/up. If we set a random speed every
	# frame, the contributions just become a fairly accurate monte-carlo 
	# sampling, and the timing always stays the same.
	alertness -= dt
	stun -= dt
	
	# Cooldown points of interest and target the one with the highest interest.
	var target_point: PointOfInterest = PointOfInterest.new(Vector3.ZERO, 0.0)
	var i: int = 0
	while i < points_of_interest.size():
		var point: PointOfInterest = points_of_interest[i]
		point.interest -= dt
		if point.interest < 0.0:
			points_of_interest[i] = points_of_interest.back()
			points_of_interest.pop_back()
			continue
		if point.interest > target_point.interest:
			target_point = point
			target = point.position
		if core.position().distance_to(point.position) < confidence_timer_radius:
			point.confidence -= dt
		i += 1
			
	if target_point.interest > 0.0:
		target = target_point.position
		if target_point.interest > hunt_interest_threshold:
			if target_point.confidence > 0.0:
				hunt(core)
			else:
				search(core, dt)
		else: if target_point.interest > listen_interest_threshold:
			listen(core)
		else:
			roam(core)

func is_sound_from_player(sound: Sound.Type) -> bool:
	if(sound == Sound.Type.BREATH
	|| sound == Sound.Type.CROUCH_FOOTSTEP
	|| sound == Sound.Type.WALK_FOOTSTEP
	|| sound == Sound.Type.RUN_FOOTSTEP):
		return true
	return false

func respond_to_sound(core: EbCore, origin: Vector3, type: Sound.Type):
	# Modify suspicion, aggression, and stun based on type and distance.
	# TODO(conner): Attenuate score (modify distance, probably) based on walls,
	# and maybe even based on ambient sounds in the room.
	var actual_distance: float = core.position().distance_to(origin)
	# var distance_score = max(1.0, actual_distance * core.velocity().length() / 4.0)
	var distance_score = actual_distance
	var interest: float = 0.0
	match type:
		Sound.Type.BREATH: interest = breath_interest_curve.sample(distance_score)
		Sound.Type.CROUCH_FOOTSTEP: interest = crouch_interest_curve.sample(distance_score)
		Sound.Type.WALK_FOOTSTEP: interest = walk_interest_curve.sample(distance_score)
		Sound.Type.RUN_FOOTSTEP: interest = run_interest_curve.sample(distance_score)
		Sound.Type.EGG_NORMAL: interest = egg_interest_curve.sample(distance_score)
		Sound.Type.EGG_GLASS: interest = glass_interest_curve.sample(distance_score)
		Sound.Type.EXHIBIT_RECORDING: interest = exhibit_interest_curve.sample(distance_score)
		Sound.Type.AIRHORN: stun = airhorn_stun_curve.sample(distance_score)
	alertness = max(alertness, interest) # TODO(conner): Lerp it?

	# Kill the player if they made a sound too close to us.
	if actual_distance < player_kill_radius && stun < 0.1 && is_sound_from_player(type):
		print("Player being killed as we speak!")
		# TODO(conner): Kill the player as we speak.
	
	points_of_interest.push_back(PointOfInterest.new(origin, interest))

func roam(core: EbCore):
	if core.nav_at_target():
		core.path_increment_waypoint()
	core.nav_goto_target(core.path_current_waypoint_position())
	core.nav_set_speed(2.0)
	previous_action = Action.ROAM
	
func listen(core: EbCore):
	core.nav_goto_me()
	core.nav_set_speed(0.0)
	previous_action = Action.LISTEN

func search(core: EbCore, dt: float):
	if core.nav_at_target():
		print("nav at target!")
		core.nav_set_speed(0.0)
		search_position_timer -= dt
		if search_position_timer < 0.0:
			search_position_target = core.find_search_radius_position(search_min_radius, search_max_radius)
			core.nav_goto_target(search_position_target)
			search_position_timer = 2.0
	else:
		core.nav_set_speed(2.0)	
	previous_action = Action.SEARCH

func hunt(core: EbCore):
	core.nav_set_speed(5.0)
	core.nav_goto_target(target)
	previous_action = Action.HUNT
	
func stunned(core: EbCore):
	core.nav_set_speed(0.0)
	core.nav_goto_me()
	previous_action = Action.STUNNED

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
