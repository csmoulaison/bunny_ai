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

class PointOfInterest:
	var position: Vector3
	var interest: float

## A measure of how much EB feels it isn't as aware as it should be and the 
## chance that it stops and listens, and is attenuated by aggression.
var anxiety: float = 0.0
## A measure of how much EB feels the player is nearby and the chance that it
## investigates a point of interest.
var suspicion: float = 0.0
## A measure of how much EB wants to fucking kill the player and the chance that
## it enters hunt mode.
var aggression: float = 0.0
## The currently selected target of interest, if that's relevant to EB's current
## action.
var target: Vector3
## The list of objects which have recently made a sounds/sounds that were heard
## by EB. Every time EB hears a sound, it adds to this list, combining sounds
## that are sufficently close together.
var points_of_interest: Array[PointOfInterest]

func process(dt: float):
	# TODO(conner): I'm thinking to add unpredictability to the timing of these
	# meters, we create a global countdown with a large (0.5 seconds, 2 seconds)
	# time span. Each countdown trigger, we set a random speed for these values
	# (anxiety, suspicion, etc) counting down/up. If we set a random speed every
	# frame, the contributions just become a fairly accurate monte-carlo 
	# sampling, and the timing always stays the same.
	anxiety += dt
	suspicion -= dt
	aggression -= dt
	# TODO(conner): Cooldown points of interest.
	
func determine_action(_state: EbCore.State) -> EbCore.State:
	# TODO(conner): Determine algorithms for scoring these. They should include
	# coefficients which are parameterized by the designer.
	var scores: Array[float]
	scores[EbCore.State.ROAM] = 1.0
	scores[EbCore.State.LISTEN] = suspicion
	scores[EbCore.State.SEARCH] = suspicion
	scores[EbCore.State.HUNT] = 0.0
	
	var best_score: float = 0.0
	var best_action: EbCore.State
	for i in range(scores.size()):
		if best_score < scores[i]:
			best_score = scores[i]
			best_action = i as EbCore.State
	return best_action
	
func search_radius_pause_length() -> float:
	# TODO(conner): Parameterize and drive from things like suspicion and
	# aggression. You get the idea.
	return randf_range(2.0, 5.0)

func respond_to_sound(origin: Vector3, type: Sound.Type):
	# TODO(conner): Respond to sounds, scoring them based on distance and type.
	# TODO(conner): Add/combine points of interest.
	# TODO(conner): Create a data resource which has all the values needed to design different
	# sounds (suspicion/aggression impact, range?, etc).
	# TODO(conner): Attenuate score based on walls, and maybe even based on ambient sounds in
	# the room.
	var _tmp
