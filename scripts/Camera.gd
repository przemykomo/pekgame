extends Camera

onready var Player = get_parent()

#const CAMERA_TURN_SPEED = 500
#
#func _ready():
#	set_process_input(true)
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#
#func _input(event):
#	if Player.is_network_master():
#		if event is InputEventMouseMotion:
#			# We are using the player node to prevent from adding the x rotation to the y rotation
#			Player.set_rotation(leftright_rotation(event.relative.x / -CAMERA_TURN_SPEED))
#			set_rotation(updown_rotation(event.relative.y / -CAMERA_TURN_SPEED))
#
#func leftright_rotation(rotation = 0):
#	return Player.get_rotation() + Vector3(0, rotation, 0)
#
#func updown_rotation(rotation = 0):
#	var toReturn = get_rotation() + Vector3(rotation, 0, 0)
#	toReturn.x = clamp(toReturn.x, PI / -2, PI / 2)
#	return toReturn
