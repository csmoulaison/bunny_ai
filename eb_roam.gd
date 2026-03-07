class_name EbRoam extends Node

enum State {
	MOVE,
	LISTEN
}

@export var current_waypoint: int = 0
@export var move_min_seconds: float = 6.0
@export var move_max_seconds: float = 12.0
@export var listen_min_seconds: float = 3.0
@export var listen_max_seconds: float = 8.0

var state: State = State.MOVE
var state_timer: float = 0.0

# TODO(conner): Take move -> listen loop out of here. Roam only handles moving
# between nodes. The brain takes us out into listen completely. Handle listen
# in its own file.
func process(path: Node, locomotion: EbLocomotion, dt: float):
	state_timer -= dt
	match state:
		State.MOVE:   move_state(path, locomotion, dt)
		State.LISTEN: listen_state(locomotion, dt)

func move_state(path: Node, locomotion: EbLocomotion, _dt: float):
	# Move towards the path nodes in sequence
	var waypoints: Array = path.get_children()
	if locomotion.at_target():
		current_waypoint += 1
		if current_waypoint >= len(waypoints):
			current_waypoint = 0
	locomotion.set_target(waypoints[current_waypoint].position)
	
	# Randomly stop to listen
	if(state_timer < 0.0):
		state_timer = randf_range(listen_min_seconds, listen_max_seconds)
		state = State.LISTEN

func listen_state(locomotion: EbLocomotion, _dt: float):
	locomotion.stop_moving()
	if(state_timer < 0.0):
		state_timer = randf_range(move_min_seconds, move_max_seconds)
		state = State.MOVE
