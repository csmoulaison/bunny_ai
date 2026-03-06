extends CharacterBody3D

# TODO(conner): Parameterize all the stuff that our indomitable designer will
# want to tweak.

# NOTE(conner): For my own sanity, it might be worth making the data which is
# associated with specific states vs global to all (or most) states explicitly
# laid out into something like a class. Then the state specifics can 

enum State { 
	ROAM_MOVE, 
	ROAM_LISTEN, 
	INVESTIGATE_MOVE_TO_TARGET, 
	INVESTIGATE_MOVE_IN_RADIUS, 
	INVESTIGATE_LISTEN, 
	HUNT 
}

class SearchRadiusPositionResult:
	var success: bool
	var position: Vector3
	func _init(suc: bool, pos: Vector3):
		success = suc
		position = pos

@export var player: Node3D
@export var path_nodes: Array[Node3D]
@export var acceleration: float = 20.0
@export var state: State
## Radii for detection zones (0: Death Zone, 1: Danger Zone, 2: Detection Zone)
@export var detection_radii: Array[float] = [ 6.0, 12.0, 24.0 ]
@export var navigation_stop_distance = 0.1
@export var investigate_search_distance_min: float = 2.0
@export var investigate_search_distance_max: float = 4.0

@export_group("State speeds")
@export var roam_speed: float = 3.0
@export var investigate_to_target_speed: float = 5.0
@export var investigate_search_speed: float = 4.0
@export var hunt_speed: float = 8.0

@export_group("State length ranges")
@export var roam_listen_min_seconds: float = 6.0
@export var roam_listen_max_seconds: float = 12.0
@export var roam_move_min_seconds: float = 6.0
@export var roam_move_max_seconds: float = 8.0
@export var investigate_search_min_seconds: float = 8.0
@export var investigate_search_max_seconds: float = 16.0
@export var investigate_listen_min_seconds: float = 3.0
@export var investigate_listen_max_seconds: float = 6.0

@onready var nav = $NavigationAgent3D

var current_path_node: int = 0
var current_target: Vector3

## Used for both exiting and entering listen state
var move_state_countdown: float = 0.0
var investigate_countdown: float = 0.0

func _ready():
	var sound_emitters = get_tree().get_nodes_in_group("SoundEmitters")
	for emitter in sound_emitters:
		emitter.sound.connect(on_sound)
		
func _physics_process(dt: float):
	var speed = 0.0
	match state:
		State.ROAM_MOVE:
			speed = roam_speed
		State.INVESTIGATE_MOVE_TO_TARGET:
			speed = investigate_to_target_speed
		State.INVESTIGATE_MOVE_IN_RADIUS:
			speed = investigate_search_speed
		State.HUNT:
			speed = hunt_speed
	
	var target_velocity: Vector3 = Vector3.ZERO
	var target_delta: Vector3 = nav.get_next_path_position() - global_transform.origin;
	# TODO(conner): I think we might not need to even check this now, as this
	# should always be caught and handled first by the state logic, and the 
	# speed is already defaulted to zero up there. The conditional rotation 
	# logic will need to change, of course, but that won't survive anyway.
	if(target_delta.length()) > navigation_stop_distance:
		target_velocity = target_delta.normalized() * speed
		$Pivot.rotation.y = atan2(target_velocity.x, target_velocity.z)
	velocity = velocity.move_toward(target_velocity, acceleration * dt)
	move_and_slide()

func on_sound(origin: Vector3, type: Sound.Type):
	print("Sound triggered | pos: ", origin, " type: ", type)
	
	# NOTE(conner): I think this detection behavior might be more coherent and
	# organic if we fold it down into different score thresholds leading to 
	# increasingly severe responses with the score being a function of sound
	# "volume" and distance from EB.
	#
	# We can layer additional conditionals on top of this base to create bespoke
	# behavior, but I think this would make things both clearer and more 
	# dynamic. It's already being gestured at discretely as is, but with some
	# situations that feel like gaps, like walking close in the detection zone.
	if state == State.HUNT:
		return
	
	var distance: float = (origin - position).length()
	if distance < detection_radii[0]: # Death zone
		if(type == Sound.Type.BREATH
		|| type == Sound.Type.CROUCH_FOOTSTEP
		|| type == Sound.Type.WALK_FOOTSTEP
		|| type == Sound.Type.RUN_FOOTSTEP):
			# TODO(conner): Kill the player
			var _tmp
	else: if distance < detection_radii[1]: # Danger zone
		if(type == Sound.Type.WALK_FOOTSTEP
		|| type == Sound.Type.RUN_FOOTSTEP):
			state = State.HUNT
	else: if distance < detection_radii[2]: # Detection zone
		if(type == Sound.Type.RUN_FOOTSTEP):
			current_target = origin
			state = State.INVESTIGATE_MOVE_TO_TARGET
			
func _process(dt: float):
	# TODO(conner): Change speed depending on state.
	match state:
		State.ROAM_MOVE:
			roam_move_state(dt)
		State.ROAM_LISTEN:
			roam_listen_state(dt)
		State.INVESTIGATE_MOVE_TO_TARGET:
			investigate_move_to_target_state(dt)
		State.INVESTIGATE_LISTEN:
			investigate_listen_state(dt)
		State.INVESTIGATE_MOVE_IN_RADIUS:
			investigate_move_in_radius_state(dt)
		State.HUNT:
			hunt_state(dt)

func roam_move_state(dt: float):
	# Move towards the path nodes in sequence
	if nav.is_target_reached():
		current_path_node += 1
		if current_path_node >= len(path_nodes):
			current_path_node = 0
	nav.target_position = path_nodes[current_path_node].position
	# Randomly stop to listen
	if(countdown_move_state(dt)):
		move_state_countdown = randf_range(roam_listen_min_seconds, roam_listen_max_seconds)
		state = State.ROAM_LISTEN
		
func roam_listen_state(dt: float):
	nav.target_position = position
	if(countdown_move_state(dt)):
		move_state_countdown = randf_range(roam_move_min_seconds, roam_move_max_seconds)
		state = State.ROAM_MOVE

func investigate_move_to_target_state(_dt: float):
	if (current_target - position).length() < 0.2:
		nav.target_position = position
		investigate_countdown = randf_range(investigate_search_min_seconds, investigate_search_max_seconds)
		move_state_countdown = randf_range(investigate_listen_min_seconds, investigate_listen_max_seconds)
		state = State.INVESTIGATE_LISTEN
	else:
		nav.target_position = current_target
	
func investigate_listen_state(dt: float):
	if(countdown_move_state(dt)):
		var count = 0
		var space_state = get_world_3d().direct_space_state
		var search_position_result: SearchRadiusPositionResult = try_find_search_radius_position(count, space_state)
		while(!search_position_result.success):
			count += 1
			search_position_result = try_find_search_radius_position(count, space_state)
		nav.target_position = search_position_result.position
		state = State.INVESTIGATE_MOVE_IN_RADIUS
	countdown_investigation_to_roam(dt)
	
func investigate_move_in_radius_state(dt: float):
	if (nav.target_position - position).length() < navigation_stop_distance * 1.5:
		nav.target_position = position
		move_state_countdown = randf_range(investigate_listen_min_seconds, investigate_listen_max_seconds)
		state = State.INVESTIGATE_LISTEN
	countdown_investigation_to_roam(dt)
	
func hunt_state(_dt: float):
	nav.target_position = player.position

func try_find_search_radius_position(count: int, space_state: PhysicsDirectSpaceState3D) -> SearchRadiusPositionResult:
	if count > 100: 
		print("Too many attempts. Giving up finding new search radius position. Tell Conner this happened.")
		return SearchRadiusPositionResult.new(true, position)
		
	# Choose a random search point within the radius range, attenuated
	# proportionally to many attempts we've made (count).
	var angle: float = randf() * 2.0 * PI
	var radius: float = sqrt(randf_range(investigate_search_distance_min - (investigate_search_distance_min * count / 100.0), investigate_search_distance_max - (investigate_search_distance_max * count / 100.0)))
	var circle_position := current_target + Vector3(radius * cos(angle), 0.0, radius * sin(angle))
	
	# Check if position on circle hits a wall, defined as having
	# an angle greater than 0.8 radians.
	var ray_origin = Vector3(position.x, position.y + 0.0, position.z)
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
		if abs(down_y - position.y) < abs(closest_y - position.y):
			closest_y = down_y
			
	if(closest_y != 100000.0):
		print("closest_y = 100000.0. Tell Conner this happened, probably shouldn't ever be the case.")
		return SearchRadiusPositionResult.new(false, Vector3.ZERO)
		
	if nav.is_target_reachable():
		return SearchRadiusPositionResult.new(true, Vector3(circle_position.x, closest_y, circle_position.z))
	print("target not reachable! ", count, nav.target_position)
	return SearchRadiusPositionResult.new(false, Vector3.ZERO)
	
func countdown_investigation_to_roam(dt: float):
	investigate_countdown -= dt
	if investigate_countdown < 0.0:
		# TODO(conner): Check for closest path node to move to. Even better 
		# would be get whichever node is furthest "forward" on the path from
		# where we are. Some dot product stuff, you know.
		state = State.ROAM_MOVE
		
func countdown_move_state(dt: float) -> bool:
	move_state_countdown -= dt
	return move_state_countdown < 0.0
