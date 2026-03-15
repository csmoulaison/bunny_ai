# NOTE(conner): The animator integrates data and responds to commands from other
# modules in order to decide how the character rig should move. Some parts of
# the animator are associated with the brain's aggression and suspicion values,
# and others are explicitly driven by the state behavior, like what position the
# head is currently looking at.

# TODO(conner): Maybe as a proof of concept we add just some shitty objects with
# rotations and stuff, at least a head maybe? Maybe a bob of the body.
class_name EbAnimator extends Node

@export var body: Node3D
@export var ik_targets: Array[Node3D]
@export var step_targets: Array[Node3D]
@export var step_distance: float = 2.0
@export var step_target_offset: float = 0.5

@onready var parents: Array[Node3D] = [ step_targets[0].get_parent_node_3d(), step_targets[1].get_parent_node_3d() ]
var is_stepping_states: Array[bool] = [ false, false ]

func process(dt: float):
	for i in ik_targets.size():
		var ik: Node3D = ik_targets[i]
		var step_target: Node3D = step_targets[i]
		step_target.global_position = parents[i].global_position + body.velocity * step_target_offset
		if !is_stepping_states[0] && !is_stepping_states[1] && ik.global_position.distance_to(step_target.global_position) > step_distance:
			is_stepping_states[i] = true
			var target: Vector3 = step_target.global_position
			var half_target: Vector3 = (ik.global_position + step_target.global_position) / 2.0
			var t = get_tree().create_tween()
			t.tween_property(ik, "global_position", half_target + ik.owner.basis.y, 0.2)
			t.tween_property(ik, "global_position", target, 0.2)
			t.tween_callback(func(): is_stepping_states[i] = false)
