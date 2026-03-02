extends CharacterBody3D

@onready var nav = $NavigationAgent3D

@export var target: Node3D
@export var speed = 3

enum BunnyState { IDLE, CHASE }

@export var state: BunnyState

func _physics_process(delta: float):
	nav.target_position = target.global_position
	var cur_position = global_transform.origin
	var next_position = nav.get_next_path_position()
	velocity = (next_position - cur_position).normalized() * speed
	move_and_slide()
