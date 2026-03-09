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
class_name EbBrain extends Node

enum Action {
	ROAM,
	LISTEN,
	MOVE_TO_TARGET,
	MOVE_IN_SEARCH_RADIUS,
	HUNT,
	STUNNED
}

@export var speed_mod: float = 0.1
@export var player_kill_radius: float = 2.0
@export var sound_combine_distance: float = 5.0
@export_group("Sound Response Configuration")
@export var breath_sound_configuration: SoundConfiguration
@export var crouch_sound_configuration: SoundConfiguration
@export var walk_sound_configuration: SoundConfiguration
@export var run_sound_configuration: SoundConfiguration
@export var egg_sound_configuration: SoundConfiguration
@export var glass_sound_configuration: SoundConfiguration
@export var exhibit_sound_configuration: SoundConfiguration
@export var airhorn_sound_configuration: SoundConfiguration

class PointOfInterest:
	var position: Vector3
	var score: float
	func _init(pos: Vector3, scr: float):
		position = pos
		score = scr

var previous_action: Action = Action.ROAM
## A measure of how much EB feels it isn't as aware as it should be and the 
## chance that it stops and listens, and is attenuated by aggression.
var anxiety: float = 0.0
## A measure of how much EB feels the player is nearby and the chance that it
## investigates a point of interest.
var suspicion: float = 0.0
## A measure of how much EB wants to fucking kill the player and the chance that
## it enters hunt mode.
var aggression: float = 0.0
## Counts down while the creature is stunned, with the creature returning to
## normal behavior when it hits 0.
var stun: float = 0.0
## The currently selected target of interest, if that's relevant to EB's current
## action.
var target: Vector3
## The list of objects which have recently made a sounds/sounds that were heard
## by EB. Every time EB hears a sound, it adds to this list, combining sounds
## that are sufficently close together.
var points_of_interest: Array[PointOfInterest]

func take_action(core: EbCore, dt: float):
	# Update "attitude meters" as time passes.
	# TODO(conner): I'm thinking to add unpredictability to the timing of these
	# meters, we create a global countdown with a large (0.5 seconds, 2 seconds)
	# time span. Each countdown trigger, we set a random speed for these values
	# (anxiety, suspicion, etc) counting down/up. If we set a random speed every
	# frame, the contributions just become a fairly accurate monte-carlo 
	# sampling, and the timing always stays the same.
	anxiety += dt
	suspicion -= dt
	aggression -= dt
	stun -= dt
	
	# Cooldown points of interest and target the closest
	var closest_distance: float = 100000.0
	for i in points_of_interest.size():
		var point: PointOfInterest = points_of_interest[i]
		var distance = core.nav_position().distance_to(point.position)
		if distance < closest_distance:
			closest_distance = distance
			target = point.position
		point.score -= dt
		if point.score < 0.0:
			points_of_interest[i] = points_of_interest.back()
			points_of_interest.pop_back()
	
	# TODO(conner): Determine algorithms for scoring these. They should include
	# coefficients which are parameterized by the designer.
	var scores: Array[float]
	scores.resize(6)
	scores[Action.ROAM] = 1.0
	scores[Action.LISTEN] = anxiety
	scores[Action.MOVE_TO_TARGET] = suspicion
	scores[Action.MOVE_IN_SEARCH_RADIUS] = suspicion
	scores[Action.HUNT] = aggression
	scores[Action.STUNNED] = stun
	
	var best_score: float = 0.0
	var best_action: Action
	for i in range(scores.size()):
		if best_score < scores[i]:
			best_score = scores[i]
			best_action = i as Action

	match best_action:
		Action.ROAM: roam(core)
		Action.LISTEN: listen(core)
		Action.MOVE_TO_TARGET: move_to_target(core)
		Action.MOVE_IN_SEARCH_RADIUS: move_in_search_radius(core)
		Action.HUNT: hunt(core)
		Action.STUNNED: stunned(core)
	core.nav_set_speed(aggression * speed_mod)

func respond_to_sound(core: EbCore, origin: Vector3, type: Sound.Type):
	# Modify suspicion, aggression, and stun based on type and distance.
	# TODO(conner): Attenuate score (modify distance, probably) based on walls,
	# and maybe even based on ambient sounds in the room.
	var distance: float = (core.nav_position() - origin).length()
	distance = max(1.0, distance * core.velocity().length() / 4.0)
	var sound: SoundConfiguration
	match type:
		Sound.Type.BREATH: sound = breath_sound_configuration
		Sound.Type.CROUCH_FOOTSTEP: sound = crouch_sound_configuration
		Sound.Type.WALK_FOOTSTEP: sound = walk_sound_configuration
		Sound.Type.RUN_FOOTSTEP: sound = run_sound_configuration
		Sound.Type.EGG_NORMAL: sound = egg_sound_configuration
		Sound.Type.EGG_GLASS: sound = glass_sound_configuration
		Sound.Type.EXHIBIT_RECORDING: sound = exhibit_sound_configuration
		Sound.Type.AIRHORN: sound = airhorn_sound_configuration
	suspicion = max(suspicion, sound.suspicion_curve.sample(distance))
	aggression = max(aggression, sound.aggression_curve.sample(distance))
	stun = max(stun, sound.stun_curve.sample(distance))

	# Kill the player if they made a sound too close to us.
	if sound.is_from_player && distance < player_kill_radius && stun < 0.1:
		print("Player being killed as we speak!")
		# TODO(conner): Kill the player as we speak.
	
	# Add sound to points of interest, combining with another if close enough.
	points_of_interest.push_back(PointOfInterest.new(origin, sound.interest_score))
	'''
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

func roam(core: EbCore):
	if core.nav_at_target():
		core.path_increment_waypoint()
	core.nav_goto_target(core.path_current_waypoint_position())
	
func listen(core: EbCore):
	core.nav_goto_me()

func move_to_target(core: EbCore):
	core.nav_goto_target(target)
	
func move_in_search_radius(core: EbCore):
	if previous_action != Action.MOVE_IN_SEARCH_RADIUS:
		var count = 0
		var space_state = core.get_world_3d().direct_space_state
		var position_result: EbCore.SearchRadiusPositionResult = core.try_find_search_radius_position(core.nav_position(), 2.0, space_state)
		while(!position_result.success):
			position_result = core.try_find_search_radius_position(core.nav_position(), 2.0 - (count / 100.0), space_state)
			count += 1
			if count > 100:
				print("CONNER: Too many attempts to find search radius position!")
				target = core.nav_position()
		target = position_result.position
	core.nav_goto_target(target)

func hunt(core: EbCore):
	core.nav_goto_target(target)
	
func stunned(_core: EbCore):
	var _tmp
