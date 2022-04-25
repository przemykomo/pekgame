extends RigidBody

var velocity = Vector3()
var puppet_position = Vector3()
var puppet_velocity = Vector3()
var puppet_rotation = Vector2()

const PLAYER_MOVE_SPEED = 4
const JUMP_VELOCITY = 3

onready var Camera = $Camera
onready var network_tick_rate = $NetworkTickRate
onready var movement_tween = $MovementTween
const CAMERA_TURN_SPEED = 500

func _ready():
	Camera.current = is_network_master()
	set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if is_network_master():
		if event is InputEventMouseMotion:
			# We are using the player node to prevent from adding the x rotation to the y rotation
			set_rotation(leftright_rotation(event.relative.x / -CAMERA_TURN_SPEED))
			Camera.set_rotation(updown_rotation(event.relative.y / -CAMERA_TURN_SPEED))

func leftright_rotation(rotation = 0):
	return get_rotation() + Vector3(0, rotation, 0)

func updown_rotation(rotation = 0):
	var toReturn = Camera.get_rotation() + Vector3(rotation, 0, 0)
	toReturn.x = clamp(toReturn.x, PI / -2, PI / 2)
	return toReturn
#
#func move_forward_back(in_direction: int):
#	velocity += get_transform().basis.z * in_direction * PLAYER_MOVE_SPEED
#
#func move_left_right(in_direction: int):
#	velocity += get_transform().basis.x * in_direction * PLAYER_MOVE_SPEED

func _physics_process(delta: float):
#	velocity = Vector3(0, self.velocity.y, 0)
	
#	if is_network_master():
	move_forward_back(int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W)))
	move_left_right(int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A)))
	
	if Input.is_action_just_pressed("jump") && $RayCast.is_colliding():
		apply_central_impulse(Vector3(0, 5, 0))
#			if is_on_floor():
#				velocity.y += JUMP_VELOCITY
	if Input.is_action_just_pressed("throw"):
		rpc("spawn_grenade", get_tree().get_network_unique_id())
#	else:
#		global_transform.origin = puppet_position
#
#		velocity.x = puppet_velocity.x
#		velocity.z = puppet_velocity.z
#
#		rotation.y = puppet_rotation.y
#		Camera.rotation.x = puppet_rotation.x
	
#	if is_on_floor():
#		velocity.y -= GRAVITY / 100
#	else:
#		velocity.y -= GRAVITY
	
#	if !movement_tween.is_active():
#		velocity = move_and_slide(velocity, Vector3.UP, true)

#puppet func update_state(p_pos, p_vel, p_rot):
#	puppet_position = p_pos
#	puppet_velocity = p_vel
#	puppet_rotation = p_rot
#
#	movement_tween.interpolate_property(self, "global_transform", global_transform, Transform(global_transform.basis, p_pos), 0.1)
#	movement_tween.start()

func _on_NetworkTickRate_timeout():
	pass
#	if is_network_master():
#		rpc_unreliable("update_state", global_transform.origin, velocity, Vector2(Camera.rotation.x, rotation.y))
#	else:
#		network_tick_rate.stop()

sync func spawn_grenade(id):
	var grenade_instance = preload("res://scenes/Grenade.tscn").instance()
	grenade_instance.name = "Grenade" + str(Network.object_name_index)
	Network.object_name_index += 1
	get_tree().get_current_scene().add_child(grenade_instance)
	grenade_instance.global_transform.origin = Camera.global_transform.origin
	grenade_instance.linear_velocity = -Camera.global_transform.basis.z * 10
