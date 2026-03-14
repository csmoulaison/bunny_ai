class_name ThrownEgg extends RigidBody3D

signal egg_collide(pos: Vector3, body: Node3D)

func _integrate_forces(state):
	if(state.get_contact_count() >= 1):
		egg_collide.emit(state.get_contact_local_position(0), state.get_contact_collider_object(0))
		queue_free()
