extends RichTextLabel

@export var enemy: Node3D

func _process(_dt: float):
	var state_string: String
	match(enemy.state):
		enemy.State.ROAM_MOVE:
			state_string = "Roam: Moving"
		enemy.State.ROAM_LISTEN:
			state_string = "Roam: Stopped"
		enemy.State.INVESTIGATE_MOVE_TO_TARGET:
			state_string = "Investigate: Moving to target"
		enemy.State.INVESTIGATE_MOVE_IN_RADIUS:
			state_string = "Investigate: Moving in search radius"
		enemy.State.INVESTIGATE_LISTEN:
			state_string = "Investigate: Stopped in search radius"
		enemy.State.HUNT:
			state_string = "Hunt"
	text = "State | " + state_string
