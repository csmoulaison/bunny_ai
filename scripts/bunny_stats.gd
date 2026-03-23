class_name BunnyStats extends Resource

var airhorn_stun_radius: float = 14.0
@export_group("Explore")
## As EB moves between [SearchNode] nodes, he modifies its 
## [member SearchNode.score] value, which represents how much EB wants to 
## explore that particular node.
## [br][br]For every node, if he is closer than this exploration distance 
## threshold, he lowers the score. If he is farther, he raises it. The amount 
## that it changes is directly proportional to how far the distance is from this
## threshold.
@export var exploration_distance_threshold: float = 10.0
## This is related to the [member exploration_distance_threshold]. If the 
## distance to a node is higher than the threshold, the amount that the score 
## raises is modulated by this value. He will "forget" about the node quicker 
## the higher this number is, and slower the lower it is.
@export var search_node_forget_rate: float = 0.1
## This is related to the [member exploration_distance_threshold]. If the 
## distance to a node is lower than the threshold, the amount that the score 
## lowers is modulated by this value. He will explore the node quicker the 
## higher this number is, and slower the lower it is.
@export var search_node_explore_rate: float = 0.5
@export_group("Hunt")
## When EB has a guess as to the player's whereabouts, it is bounded by a
## certain radius. EB assumes the player might be somewhere inside this radius.
## Over time when EB isn't hearing any sounds, the radius passively grows, and
## [member player_guess_max_radius] is the maximum size it grows toward.
@export var player_guess_max_radius: float = 14.0
## Determines the rate at which EB's player search radius grows. See [member
## player_guess_max_radius] documentation for an explanation of the radius.
@export var player_guess_radius_expansion_rate: float = 2.0
## As EB hears successive sounds by the player, he integrates them together and,
## inferring things like the player's possible velocity by comparing the 
## difference in positions of recent sounds, and slowly converging towards a
## more accurate picture the more sounds he hears. 
## [br][br]However, if a sound he hears is further away from the last heard 
## sound than [member player_guess_reset_distance_threshold], the radius and 
## velocity guesses are reset, because the sound is far enough away that he 
## isn't sure how to integrate them anymore.
@export var player_guess_reset_distance_threshold: float = 12.0
## As EB tries to integrate the sounds he hears, one of the variables he tracks
## is a guess about the player's current direction and speed. He uses that 
## guessed velocity to move his search radius in that direction over time.
## [br][br][member player_guess_velocity_depreciation_rate] sets how quickly 
## this speed slows down over time, as EB can't be sure the player is still 
## moving in the same direction, and if he isn't hearing any more sounds, it is 
## probably a good idea for him to assume the player might have stopped.
@export var player_guess_velocity_depreciation_rate: float = 0.004
## Hearing sounds causes the "intensity" of EB's guess about the player to rise,
## and the intensity rising above a certain level is what triggers EB to start
## actively hunting for the player. 
## [br][br][member player_guess_intensity_depreciation_rate] sets how quickly
## this intensity lowers over time, which eventually causes EB to lose interest
## in the hunt and go back to exploring.
@export var player_guess_intensity_depreciation_rate: float = 0.01
## When EB hears a sound through a wall, his ability to hear it is is attenuated
## by [member sound_wall_obstruction_modifier]. This is done by dividing the 
## apparent distance to the sound by this value. This means lower numbers mean
## a worse ability to hear, higher numbers means better hearing.
@export var sound_wall_obstruction_modifier: float = 0.25
## NOTE: This is not actually in place yet, the wall functions for both.
## [br][br]This works the same way as [member sound_wall_obstruction_modifier], but when
## the sound is heard through an obstacle rather than a wall, when the player is
## crouching behind a cabinet, for instance. It should be a higher number than
## the wall variant, as walls are probably worse for hearing than obstacles.
@export var sound_obstacle_obstruction_modifier: float = 0.5
## Breath and player footsteps heard within this radius result in a player 
## death, assuming [member can_kill_player] is true. Right now, death is a signal
## picked up by the Director node to reset the positions of EB and the player,
## and EB also does some resetting of his own state. We will want to discuss how
## we want player death to work in the final game.
@export var player_kill_radius: float = 3.0
@export_group("Speeds")
## The speed at which EB moves when doing the current goal behavior is equal to 
## ([member explore_speed_distance_multiplier] * distance to target), and then 
## the result is clamped between [member min_explore_speed] and 
## [member max_explore_speed].
## [br][br]The effect is that EB moves quicker to get to nodes he is further 
## away from.
@export var explore_speed_distance_multiplier: float = 1.0
## The minimum speed for moving towards a target node while doing the current 
## explore behavior. Ensures that the speed doesn't go below this value 
## after calculating the speed from [member explore_speed_distance_multiplier].
@export var min_explore_speed: float = 3.0
## The maximum speed for moving towards a target node while doing the current
## explore behavior. Ensures that the speed doesn't go above this value after 
## calculating the speed from [member idle_speed_distance_multiplier].
@export var max_explore_speed: float = 6.0
## See [member explore_speed_distance_multiplier]. This works exactly the same
## way, but while hunting for the player.
@export var hunt_speed_distance_multiplier: float = 1.0
## See [member min_explore_speed]. This works exactly the same way, but while 
## hunting for the player.
@export var min_hunt_speed: float = 2.0
## See [member max_explore_speed]. This works exactly the same way, but while 
## hunting for the player.
@export var max_hunt_speed: float = 8.0
## See [member explore_speed_distance_multiplier]. This works exactly the same
## way, but while distracted, by an egg for instance.
@export var distracted_speed_distance_multiplier: float = 1.0
## See [member min_explore_speed]. This works exactly the same way, but while 
## distracted, by an egg for instance.
@export var min_distracted_speed: float = 3.0
## See [member max_explore_speed]. This works exactly the same way, but while 
## distracted, by an egg for instance.
@export var max_distracted_speed: float = 8.0
@export_group("State lengths")
## Determines the minimum amount of seconds that the player should move while
## exploring before stopping to listen.
## [br][br]Truth be told, after playing with it for a bit, I'm not sure I like
## the random stops to listen. EB already sometimes stops when he reaches target
## nodes, and the extra stops to listen just make it easier for the player to 
## exploit his movement. I don't know, though, so I'm keeping it in for now.
@export var min_move_seconds: float = 4.0
## Determines the maximum amount of seconds that the player should move while
## exploring before stopping to listen. See [member min_move_seconds].
@export var max_move_seconds: float = 8.0
## After moving for some number of seconds while exploring, EB will randomly
## stop to listen, and this is the minimum amount of seconds he will do so for. 
## [br][br]As mentioned in the documentation for [member min_move_seconds], I'm 
## not sure I like this behavior, but it's still here for now.
@export var min_listen_seconds: float = 2.0
## The maximum amount of seconds EB will listen for after randomly stopping 
## during exploration.
@export var max_listen_seconds: float = 3.0
## When EB reaches a search node during explanation, he will think for a random
## number of seconds before moving to the next search node. This is the minimum
## seconds for that. I have it set here to a negative value, which ends up 
## giving him a chance of not stopping at all, or more specifically, of immediately
## returning to the move state after stopping to think. 
## [br][br]Given that the time selected is in a random range, the current min 
## and max values I have currently set (-1.0 to 2.0) will give a 1 in 3 chance
## that EB immediately starts moving again.
@export var min_think_seconds: float = 0.0
## This is the maximum value for- oh jeez just read [member min_think_seconds].
@export var max_think_seconds: float = 3.0
