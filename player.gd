extends CharacterBody3D

signal sound(pos: Vector3, type: Sound.Type)

enum MoveState {
	WALK,
	CROUCH,
	RUN
}

@export var crouch_speed = 1.5
@export var walk_speed = 4.0
@export var run_speed = 10.0

@export var crouch_height = 0.75
@export var normal_height = 1.5

@export var crouch_footstep_interval = 1.0
@export var walk_footstep_interval = 0.6
@export var run_footstep_interval = 0.3

@export var acceleration = 50.0
@export var fall_acceleration = 75.0
@export var mouse_sensitivity = 0.01

@onready var camera: Node3D = $CameraPivot

var move_state: MoveState
var target_velocity = Vector3.ZERO
var footstep_cooldown = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(dt: float):
	var input  = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input.x += 1.0
	if Input.is_action_pressed("move_left"):
		input.x -= 1.0
	if Input.is_action_pressed("move_back"):
		input.y += 1.0
	if Input.is_action_pressed("move_forward"):
		input.y -= 1.0
		
	if Input.is_action_pressed("crouch"):
		move_state = MoveState.CROUCH
	else: if Input.is_action_pressed("run"):
		move_state = MoveState.RUN
	else:
		move_state = MoveState.WALK
	
	# Set state specific values
	var footstep_sound: Sound.Type
	var current_speed: float
	var cam_target_height = normal_height
	var footstep_interval: float
	var footstep_volume_db: float
	match move_state:
		MoveState.CROUCH:
			footstep_sound = Sound.Type.CROUCH_FOOTSTEP
			current_speed = crouch_speed
			cam_target_height = crouch_height
			footstep_interval = crouch_footstep_interval
			footstep_volume_db = -30.0
		MoveState.WALK:
			footstep_sound = Sound.Type.WALK_FOOTSTEP
			current_speed = walk_speed
			footstep_interval = walk_footstep_interval
			footstep_volume_db = -15.0
		MoveState.RUN:
			footstep_sound = Sound.Type.RUN_FOOTSTEP
			current_speed = run_speed
			footstep_interval = run_footstep_interval
			footstep_volume_db = 0.0
		MoveState.WALK, MoveState.RUN:
			cam_target_height = normal_height
			
	camera.position.y = move_toward(camera.position.y, cam_target_height, dt * 6.0)
	
	if input != Vector2.ZERO:
		input = input.normalized()
		footstep_cooldown -= dt
		if(footstep_cooldown < 0.0):
			footstep_cooldown = footstep_interval
			$FootstepSound.volume_db = footstep_volume_db
			$FootstepSound.play()
			emit_signal("sound", position, footstep_sound)
	else:
		footstep_cooldown = 0.0
			
	var direction = (transform.basis * Vector3(input.x, 0.0, input.y))
	target_velocity.x = move_toward(target_velocity.x, direction.x * current_speed, acceleration * dt)
	target_velocity.z = move_toward(target_velocity.z, direction.z * current_speed, acceleration * dt)
	if not is_on_floor():
		velocity.y = velocity.y - (fall_acceleration * dt)
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z
	move_and_slide()
	
func _input(event):
	if event is InputEventMouseMotion:
		$CameraPivot.rotate_object_local(Vector3.LEFT, event.relative.y * mouse_sensitivity)
		rotate_object_local(Vector3.DOWN, event.relative.x * mouse_sensitivity)		
			
		if $CameraPivot.rotation.x < deg_to_rad(-89) or $CameraPivot.rotation.x > deg_to_rad(89):
			$CameraPivot.rotation.x = clamp($CameraPivot.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
		orthonormalize()
		$CameraPivot.orthonormalize()
