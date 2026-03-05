extends Camera3D

@export var enemy: Node3D

var enemy_velocity: Vector3
 
func _process(_dt: float):
	if enemy.velocity != Vector3.ZERO:
		enemy_velocity = enemy.velocity.normalized()
	position = enemy.position + Vector3(-enemy_velocity.x * 2.0, 2.5, -enemy_velocity.z * 2.0)
	look_at(enemy.position + Vector3(0.0, 1.0, 0.0))
