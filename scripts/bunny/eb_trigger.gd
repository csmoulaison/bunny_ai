class_name EbTrigger extends Area3D

@export_group("Emit Sound")
@export var trigger_sound: bool
@export var sound_origin: Vector3
@export var sound_type: Sound.Type
@export_group("Set Stats")
@export var trigger_set_stats: bool
@export var stats: BunnyStats
@export_group("Set Can Hunt Player")
@export var trigger_set_can_hunt_player: bool
@export var can_hunt_player: bool
@export_group("Set Can Kill Player")
@export var trigger_set_can_kill_player: bool
@export var can_kill_player: bool
@export_group("Set Explore Behavior")
@export var trigger_set_explore_behavior: bool
@export var behavior: Bunny.ExploreBehavior
@export var explore_zones: Array[SearchZone]
@export var point_center: Node3D
@export var point_radius: float
@export var patrol_nodes: Array[SearchZone]

var player: Node3D

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	assert(player != null)

func _on_body_entered(body: Node3D):
	if body != player:
		return
	
	if trigger_sound:
		EventBus.eb_sound.emit(sound_origin, sound_type)
	if trigger_set_stats:
		EventBus.eb_set_stats.emit(stats)
	if trigger_set_can_hunt_player:
		EventBus.eb_set_can_hunt_player.emit(can_hunt_player)
	if trigger_set_can_kill_player:
		EventBus.eb_set_can_kill_player.emit(can_kill_player)
	if trigger_set_explore_behavior:
		match behavior:
			Bunny.ExploreBehavior.ZONE_STATIC:
				EventBus.eb_set_explore_zone_static.emit(explore_zones)
			Bunny.ExploreBehavior.ZONE_FOLLOW_GUESS:
				EventBus.eb_set_explore_zone_follow_guess.emit(explore_zones)
			Bunny.ExploreBehavior.ZONE_FOLLOW_PLAYER:
				EventBus.eb_set_explore_zone_follow_player.emit()
			Bunny.ExploreBehavior.RADIUS_STATIC:
				EventBus.eb_set_explore_radius_static.emit(point_center, point_radius)
			Bunny.ExploreBehavior.RADIUS_FOLLOW_PLAYER:
				EventBus.eb_set_explore_radius_follow_player.emit(point_radius)
			Bunny.ExploreBehavior.PATROL:
				EventBus.eb_set_explore_patrol.emit(patrol_nodes)
			Bunny.ExploreBehavior.ALWAYS_HUNT:
				EventBus.eb_set_explore_always_hunt.emit()
			Bunny.ExploreBehavior.STAY_IN_PLACE:
				EventBus.eb_set_explore_stay_in_place.emit(point_center)
