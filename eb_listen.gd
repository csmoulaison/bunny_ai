class_name EbListen extends Node

func process(locomotion: EbLocomotion, _dt: float):
	locomotion.stop_moving()
