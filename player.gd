extends CharacterBody3D

signal attract(pos: Vector3, score: float)

@export var speed = 10.0
@export var acceleration = 50.0
@export var fall_acceleration = 75.0
@export var mouse_sensitivity = 0.01
@export var footsteps_per_second = 0.5

var target_velocity = Vector3.ZERO
var footstep_cooldown = footsteps_per_second * 0.5

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
		
	if input != Vector2.ZERO:
		input = input.normalized()
		footstep_cooldown -= dt
		if(footstep_cooldown < 0.0):
			footstep_cooldown = footsteps_per_second
			$FootstepSound.play()
			emit_signal("attract", position, 5.0)
	else:
		footstep_cooldown = footsteps_per_second * 0.5
			
	var direction = (transform.basis * Vector3(input.x, 0.0, input.y))
		
	target_velocity.x = move_toward(target_velocity.x, direction.x * speed, acceleration * dt)
	target_velocity.z = move_toward(target_velocity.z, direction.z * speed, acceleration * dt)
	
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
