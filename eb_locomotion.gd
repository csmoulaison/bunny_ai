class_name EbLocomotion extends Node

@export var body: CharacterBody3D
@export var pivot: Node3D
@export var nav: NavigationAgent3D
@export var navigation_stop_distance: float = 0.1
@export var acceleration: float = 20.0

# TODO(conner): Drive speed from brain.
var speed: float = 8.0

func physics_process(dt: float):
	var desired_velocity: Vector3 = Vector3.ZERO
	var target = nav.get_next_path_position()
	var delta: Vector3 = target - body.global_transform.origin;

	if(delta.length()) > navigation_stop_distance:
		desired_velocity = delta.normalized() * speed
		pivot.rotation.y = atan2(desired_velocity.x, desired_velocity.z)
	else:
		stop_moving()
	body.velocity = body.velocity.move_toward(desired_velocity, acceleration * dt)
	body.move_and_slide()

func set_target(position: Vector3):
	nav.target_position = position

func stop_moving():
	set_target(body.position)

func at_target() -> bool:
	var delta = target_delta()
	return delta.length() < navigation_stop_distance

func target_position() -> Vector3:
	return nav.get_next_path_position()

func target_delta() -> Vector3:
	var target = target_position()
	return target - body.global_transform.origin;
