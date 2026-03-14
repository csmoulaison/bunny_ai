extends Node

@export var encounter: Encounter
@export var player: Node3D
@export var eb: EbRoot

func start():
	print("start")
	eb.path = encounter.path
	eb.global_position = encounter.eb_spawn.global_position
	player.global_position = encounter.player_spawn.global_position

func _ready():
	start()

func _process(dt: float):
	if eb.player_killed_this_frame:
		start()
		eb.player_killed_this_frame = false
