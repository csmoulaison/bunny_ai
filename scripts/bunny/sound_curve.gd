class_name SoundCurve extends Curve
## Determines the relationship between EB's response to a certain sound and the
## distance he hears it at.
##
## The X axis is the distance between 0.0 and 1.0. This is multiplied by 100 in
## the code, so 1.0 actually stands for 100 units, 0.5 for 50 units, etc. The Y
## axis is the "response" level associated with the given distance. The response
## level does something different for different categories of sound.
## [br][br][b]Player Sounds (footsteps, breath):[/b] The response level for
## these sounds determine how much information about the player's position and
## velocity EB recieves on hearing it.
## [br][b]Distraction Sounds (eggs, exhibits):[/b] The response level for
## these sounds determine how long EB will be distracted by a certain sound for
## after he moves to its source. If the response is 0 when he hears it, he will
## not be distracted. If it is above 0, the timer is currently set to 10.0 
## seconds * response level.
## [br][b]Airhorn Sound:[/b] The response level for the airhorn sound determines
## whether EB is stunned by it. If the response is 0, he is not stunned,
## otherwise he is.
##[br][br]The response curve is modulated by [member 
## Bunny.sound_wall_obstruction_modifier] and [member 
## Bunny.sound_obstacle_obstrction_modifier], both of them raising EB's apparent
## distance to the sound.
## [br][br][b]Techinical Details:[/b]: For player sounds, the affect it has on
## EB's player guess is as follows: the velocity guess and search radius are 
## lerped towards a higher accuracy and the intensity is lerped towrads 1.0, 
## with the response as t.
## [br][center]radius: lerp(radius, 0.0, response)[/center]
## [br][center]velocity: lerp(guess, actual, response)[/center]
## [br][center]intensity: lerp(intensity, 1.0, response)[/center]

func _init():
	min_domain = 0.0
	max_domain = 25.0
	min_value = 0.0
	max_value = 15.0
