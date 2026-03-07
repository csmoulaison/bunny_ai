# NOTE(conner): This class is the orchestrator of all the behaviors associated 
# with EB, and it also contains everything that is needed to communicate with 
# EB from the outside, responding to signals, for instance.
class_name EbCore extends CharacterBody3D

enum State {
	ROAM = 0,
	# TODO(conner): Create listen script and integrate.
	LISTEN = 1,
	SEARCH = 2,
	HUNT = 3
}

@export var path: Node

# TODO(conner): Once we have an absolute MVP going for Brain 2.0, reimplement
# Brain 1.0 and make sure it interoperates. Add some optional complications to
# 1.0 as well. Maybe making continuousness and/or dynamic ranges optional isn't
# THAT hard, idk.
@onready var brain: EbBrain = $Logic/Brain
@onready var roam: EbRoam = $Logic/Roam
@onready var search: EbSearch = $Logic/Search
@onready var hunt: EbHunt = $Logic/Hunt
@onready var locomotion: EbLocomotion = $Logic/Locomotion

var state: State = State.ROAM

func _ready():
	var sound_emitters = get_tree().get_nodes_in_group("SoundEmitters")
	for emitter in sound_emitters:
		emitter.sound.connect(on_sound)
		
	locomotion.stop_moving()

func _process(dt: float):
	match state:
		State.ROAM:   roam.process(path, locomotion, dt)
		State.SEARCH: search.process(dt)
		State.HUNT:   hunt.process(dt)

func _physics_process(dt: float):
	locomotion.physics_process(dt)

func on_sound(origin: Vector3, type: Sound.Type):
	brain.respond_to_sound(origin, type)
