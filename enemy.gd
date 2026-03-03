extends CharacterBody3D

enum BunnyChaseState { PATROL, DISTRACTED, INVESTIGATE, CHASE }

# Bunny Chase Logic
# Whenever an object which makes conspicuous noises makes a conspicuous noise,
# it emits an "attract" signal, which is handled by our _on_attract function 
# which keeps track of those signals.
#
# When an attraction is emitted, its position is checked against the existing
# targets for whether it falls within a distance threshold. If it is within the
# threshold, the score associated with the attractor is added to the matching
# target and its position is updated to match the new attraction. If not, a new
# target is created with the associated score.
#
# The target scores are constantly depreciating, so the most recent attractions
# are more likely to be engaged with. Every tick, we see if any targets have a
# high enough threshold to warrant a response, and our hare reacts accordingly.
class Target:
	var position: Vector3
	var score: float

@export var player: Node3D
@export var path_nodes: Array[Node3D]
@export var speed = 3.0
@export var acceleration = 20.0
@export var state: BunnyChaseState

@onready var nav = $NavigationAgent3D
@onready var current_node = 0

var targets: Array[Target]

func _ready():
	var attractors = get_tree().get_nodes_in_group("Attractors")
	for attractor in attractors:
		attractor.attract.connect(on_attract)
	
func on_attract(pos: Vector3, score: float):
	# TODO(conner): Calculate actual score based on distance and combine with
	# previous targets as needed. Maybe add a third parameter for the "staying
	# power" of the attraction, which is either averaged with or overwrites the
	# previous value of the target, and controls how slow the cooldown effect is.
	print("Attract | pos: ", pos, " score: ", score)
	
func _process(dt: float):
	# TODO(conner): Figure out current target/state based on currently tracked
	# targets. Represent all possible actions as utility functions, and add a 
	# bias towards recently switch-to states to prevent schizophrenia.
	var k = 0 # temp to prevent error

func _physics_process(dt: float):
	nav.target_position = path_nodes[current_node].position
	var cur_position = global_transform.origin
	var next_position = nav.get_next_path_position()
	velocity = velocity.move_toward((next_position - cur_position).normalized() * speed, acceleration * dt)
	move_and_slide()
	
	if nav.is_target_reached():
		current_node += 1
		if current_node >= len(path_nodes):
			current_node = 0
