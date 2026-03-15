extends Node

@export var player: Node3D
@export var bunny: Node3D

@onready var initial_player_position: Vector3 = player.global_position

func _ready() -> void:
	bunny.player_killed.connect(on_player_killed)

func on_player_killed():
	player.global_position = initial_player_position
