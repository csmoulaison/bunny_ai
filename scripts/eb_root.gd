class_name EbRoot extends CharacterBody3D

@export var use_smarter_ai: bool
@export var explore_zones: Array[Node3D]
@export var search_zones: Node3D
@export var path: Node
@export var player: Node3D

var player_killed_this_frame: bool = false
