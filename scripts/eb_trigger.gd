class_name EbTrigger extends Area3D

signal eb_sound(origin: Vector3, type: Sound.Type)
signal eb_set_explore_behavior(zones: Array[SearchZone], zone_behavior: Bunny.ExploreZoneBehavior)
signal eb_set_guard_behavior(node: SearchNode, nearby_max_distance: float)
signal eb_set_patrol_behavior(path: Array[SearchNode])
signal eb_set_hunt_behavior(behavior: Bunny.HuntBehavior)
signal eb_set_can_kill_player(value: bool)

@export_category("eb_sound")
@export var trigger_sound: bool
@export var trigger_sound_origin: Vector3
@export var trigger_sound_type: Sound.Type
@export_category("set idle behavior")
@export var trigger_set_idle_behavior: bool
@export var behavior_to_set: Bunny.IdleBehavior
@export_group("eb_set_explore_behavior")
@export var trigger_explore_zones: Array[SearchZone]
@export var trigger_explore_zone_behavior: Bunny.ExploreZoneBehavior
@export_group("eb_set_guard_behavior")
@export var trigger_guard_node: SearchNode
@export var trigger_guard_nearby_max_distance: float
@export_group("eb_set_patrol_behavior")
@export var trigger_patrol_nodes: Array[SearchZone]
@export_category("eb_set_hunt_behavior")
@export var trigger_set_hunt_behavior: bool
@export var trigger_hunt_behavior: Bunny.HuntBehavior
@export_category("eb_set_can_kill_player")
## Kind of confusing, but this one sets whether this signal is fired.
@export var trigger_set_kill_player: bool
## Kind of confusing, but this one sets the actual value of can_kill_player.
@export var trigger_set_can_kill_player: bool

var player: Node3D

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	assert(player != null)

func _on_body_entered(body: Node3D):
	if body != player:
		return
	
	if trigger_sound:
		eb_sound.emit(trigger_sound_origin, trigger_sound_type)
	if trigger_set_idle_behavior:
		match behavior_to_set:
			Bunny.IdleBehavior.EXPLORE:
				eb_set_explore_behavior.emit(trigger_explore_zones)
			Bunny.IdleBehavior.GUARD_NODE:
				eb_set_guard_behavior.emit(trigger_guard_node, trigger_guard_nearby_max_distance)
			Bunny.IdleBehavior.PATROL_NODE_CYCLE:
				eb_set_patrol_behavior.emit(trigger_patrol_nodes)
	if trigger_set_hunt_behavior:
		eb_set_hunt_behavior.emit(trigger_hunt_behavior)
	if trigger_set_kill_player:
		eb_set_can_kill_player.emit(trigger_set_can_kill_player)
