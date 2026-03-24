extends Node

signal eb_sound(origin: Vector3, type: Sound.Type)
signal eb_set_stats(stats: BunnyStats)
signal eb_set_can_hunt_player(can_hunt: bool)
signal eb_set_can_kill_player(can_kill: bool)
signal eb_set_explore_zone_static(zones: Array[SearchZone])
signal eb_set_explore_zone_follow_guess(initial_zones: Array[SearchZone])
signal eb_set_explore_zone_follow_player()
signal eb_set_explore_radius_static(center: Vector3, radius: float)
signal eb_set_explore_radius_follow_player(radius: float)
signal eb_set_explore_patrol(path: Array[Node3D])
signal eb_set_explore_stay_in_place(pos: Vector3)
signal eb_set_explore_always_hunt()
