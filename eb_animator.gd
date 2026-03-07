# NOTE(conner): The animator integrates data and responds to commands from other
# modules in order to decide how the character rig should move. Some parts of
# the animator are associated with the brain's aggression and suspicion values,
# and others are explicitly driven by the state behavior, like what position the
# head is currently looking at.

# TODO(conner): Maybe as a proof of concept we add just some shitty objects with
# rotations and stuff, at least a head maybe? Maybe a bob of the body.
class_name EbAnimator extends Node
