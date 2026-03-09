# NOTE(conner): This class is the orchestrator of all the behaviors associated 
# with EB, and it also contains everything that is needed to communicate with 
# EB from the outside, responding to signals, for instance.
class_name EbCore extends Node

@export var _root: CharacterBody3D
@export var _brain: EbBrain
@export var _pivot: Node3D
@export var _nav: NavigationAgent3D
@export var _waypoints: Array[Node]
@export var _current_waypoint: int = 0
@export var _navigation_stop_distance: float = 0.1
@export var _acceleration: float = 20.0
var _speed: float = 0.0

func _ready():
	var sound_emitters = get_tree().get_nodes_in_group("SoundEmitters")
	for emitter in sound_emitters:
		emitter.sound.connect(on_sound)

	_waypoints = _root.path.get_children()
		
	nav_goto_me()
	
func _process(dt: float):
	_brain.take_action(self, dt)

func _physics_process(dt: float):
	var desired_velocity: Vector3 = Vector3.ZERO
	var target = _nav.get_next_path_position()
	var delta: Vector3 = target - _root.global_transform.origin;

	if(delta.length()) > _navigation_stop_distance:
		desired_velocity = delta.normalized() * _speed
		_pivot.rotation.y = atan2(desired_velocity.x, desired_velocity.z)
	else:
		_nav.target_position = _root.position
	_root.velocity = _root.velocity.move_toward(desired_velocity, _acceleration * dt)
	_root.move_and_slide()
	
# ================
# SIGNAL RESPONSES
# ================
func on_sound(origin: Vector3, type: Sound.Type): 
	_brain.respond_to_sound(self, origin, type)
	
# ====
# PATH
# ====
func path_waypoints() -> Array[Node]:
	return _waypoints

func path_increment_waypoint():
	_current_waypoint += 1
	if _current_waypoint >= len(_waypoints):
		_current_waypoint = 0

func path_current_waypoint_position() -> Vector3:
	assert(_waypoints[_current_waypoint] is Node3D)
	return _waypoints[_current_waypoint].position

# ==========
# NAVIGATION
# ==========
func nav_position() -> Vector3:
	return _root.position

func nav_set_speed(speed: float):
	_speed = speed

func nav_goto_target(pos: Vector3):
	_nav.target_position = pos

func nav_goto_me():
	nav_goto_target(_root.position)

func nav_at_target() -> bool:
	return nav_target_delta().length() < _navigation_stop_distance

func nav_target_position() -> Vector3:
	return _nav.get_next_path_position()

func nav_target_delta() -> Vector3:
	return nav_target_position() - _root.global_transform.origin;

func nav_target_reachable() -> bool:
	return _nav.is_target_reachable()

# =============
# SEARCH RADIUS
# =============
class SearchRadiusPositionResult:
	var success: bool
	var position: Vector3
	func _init(suc: bool, pos: Vector3):
		success = suc
		position = pos

func try_find_search_radius_position(center: Vector3, radius: float, space_state: PhysicsDirectSpaceState3D) -> SearchRadiusPositionResult:	
	# Choose a random search point within the radius range, attenuated
	# proportionally to many attempts we've made (count).
	var angle: float = randf() * 2.0 * PI
	var circle_position := center + Vector3(radius * cos(angle), 0.0, radius * sin(angle))
	
	# Check if position on circle hits a wall, defined as having
	# an angle greater than 0.8 radians.
	var ray_origin = Vector3(_root.position.x, _root.position.y + 0.0, _root.position.z)
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
		if abs(down_y - _root.position.y) < abs(closest_y - _root.position.y):
			closest_y = down_y
			
	if(closest_y != 100000.0):
		print("closest_y = 100000.0. Tell Conner this happened, probably shouldn't ever be the case.")
		return SearchRadiusPositionResult.new(false, Vector3.ZERO)
		
	if nav_target_reachable():
		return SearchRadiusPositionResult.new(true, Vector3(circle_position.x, closest_y, circle_position.z))
	else:
		print("Target not reachable!", nav_target_position())
		return SearchRadiusPositionResult.new(false, Vector3.ZERO)
