class_name EbSearch extends Node

enum State {
	MOVE_TO_TARGET,
	MOVE_IN_RADIUS,
	STOP_IN_RADIUS
}

class SearchRadiusPositionResult:
	var success: bool
	var position: Vector3
	func _init(suc: bool, pos: Vector3):
		success = suc
		position = pos

@export var search_radius_min: float = 2.0
@export var search_radius_max: float = 4.0

var state: State = State.MOVE_TO_TARGET
var state_timer: float = 0.0
var target: Vector3

func process(my_position: Vector3, locomotion: EbLocomotion, dt: float):
	match state:
		State.MOVE_TO_TARGET:
			move_to_target_state(my_position, locomotion)
		State.MOVE_IN_RADIUS:
			move_in_radius_state()
		State.STOP_IN_RADIUS:
			stop_in_radius_states()

func move_to_target_state(my_position: Vector3, locomotion: EbLocomotion):
	if (target - my_position).length() < 0.2:
		locomotion.set_target(my_position)
		investigate_countdown = randf_range(investigate_search_min_seconds, investigate_search_max_seconds)
		move_state_countdown = randf_range(investigate_listen_min_seconds, investigate_listen_max_seconds)
		state = State.STOP_IN_RADIUS
	else:
		nav.target_position = current_target

func move_in_radius_state():
	var _tmp

func stop_in_radius_states():
	var _tmp

func try_find_search_radius_position(locomotion: EbLocomotion, my_position: Vector3, count: int, space_state: PhysicsDirectSpaceState3D) -> SearchRadiusPositionResult:
	if count > 100: 
		print("Too many attempts. Giving up finding new search radius position. Tell Conner this happened.")
		return SearchRadiusPositionResult.new(true, my_position)
		
	# Choose a random search point within the radius range, attenuated
	# proportionally to many attempts we've made (count).
	var angle: float = randf() * 2.0 * PI
	var radius: float = sqrt(randf_range(search_radius_min - (search_radius_min * count / 100.0), search_radius_max - (search_radius_max * count / 100.0)))
	var circle_position := target + Vector3(radius * cos(angle), 0.0, radius * sin(angle))
	
	# Check if position on circle hits a wall, defined as having
	# an angle greater than 0.8 radians.
	var ray_origin = Vector3(my_position.x, my_position.y + 0.0, my_position.z)
	var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, circle_position)
	var result = space_state.intersect_ray(ray_query)
	if !result.is_empty():
		var normal: Vector3 = result["normal"]
		var dot: float = normal.dot(Vector3.UP)
		if dot >= 0.8 || dot <= -0.8:
			print("Collided with wall!")
			return SearchRadiusPositionResult.new(false, Vector3.ZERO)
			
	# Cast for closest y floor position
	var closest_y: float = 100000.0
	# UP from position
	var ray_end = circle_position + (Vector3.UP * 100.0)
	ray_query = PhysicsRayQueryParameters3D.create(circle_position, ray_end)
	result = space_state.intersect_ray(ray_query)
	if !result.is_empty():
		closest_y = result["position"].y
	# DOWN from position
	ray_end = circle_position + (Vector3.DOWN * 100.0)
	ray_query = PhysicsRayQueryParameters3D.create(circle_position, ray_end)
	result = space_state.intersect_ray(ray_query)
	if !result.is_empty():
		var down_y = result["position"].y
		if abs(down_y - my_position.y) < abs(closest_y - my_position.y):
			closest_y = down_y
			
	if(closest_y != 100000.0):
		print("closest_y = 100000.0. Tell Conner this happened, probably shouldn't ever be the case.")
		return SearchRadiusPositionResult.new(false, Vector3.ZERO)
		
	if locomotion.target_reachable():
		return SearchRadiusPositionResult.new(true, Vector3(circle_position.x, closest_y, circle_position.z))
	print("target not reachable! ", count, locomotion.target())
	return SearchRadiusPositionResult.new(false, Vector3.ZERO)
