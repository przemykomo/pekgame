extends RigidBody

export var jump_velocity = 5
export var acceleration = 5
export var accel_multiplier = 1.0
export var speed = 25
export var max_speed = 6
export (float, 0.01,1.0) var stop_speed = 0.1

var velocity = Vector3()

var mouse_input = Vector2()
onready var eyes = $Body/Camera
onready var aimcast = $Body/Camera/AimCast
onready var body = $Body
onready var feet = $Feet
export var view_sensitivity = 60.0
export var is_on_floor = false
var old_move_input = Vector2.ZERO
export var move_input = Vector2.ZERO

func _ready():
	if is_network_master():
		eyes.current = true
		linear_damp = 1.0
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	if feet.is_colliding():
		is_on_floor = true
	#	friction = 1.0
		accel_multiplier = 1.0
		
	if is_network_master():
		#reset friction to zero to avoid sticking to walk when velocity is applied
	#	if friction >= 0: friction = 0
		
		#is_on_floor = false
		
		old_move_input = move_input
		move_input = Input.get_vector("left","right","down","up")
		if old_move_input != move_input:
			rpc('update_input', move_input)
		
		if mouse_input.length() > 0:
			eyes.rotation_degrees.x -= mouse_input.y * view_sensitivity * delta;
			eyes.rotation_degrees.x = clamp(eyes.rotation_degrees.x,-80,80)
			body.rotation_degrees.y -= mouse_input.x * view_sensitivity * delta;
			mouse_input = Vector2.ZERO
			rpc('update_rotation', eyes.rotation_degrees.x, body.rotation_degrees.y)
		
		if Input.is_action_just_pressed("throw"):
			rpc("spawn_grenade", get_tree().get_network_unique_id())
		
		if Input.is_action_just_pressed("jump"): # and is_on_floor:
			accel_multiplier = 0.1
			rpc('jump')
		
		if Input.is_action_just_pressed("fire"):
			rpc('fire')

func _integrate_forces(state):
	if state.linear_velocity.length() < max_speed:
		var dir = Vector3()
		dir += move_input.x * body.global_transform.basis.x;
		dir -= move_input.y * body.global_transform.basis.z;
		velocity = lerp(velocity, dir * speed, acceleration * accel_multiplier / 60)
		add_central_force(velocity)
	
	#if is_network_master():
		#limit max speed
#	if state.linear_velocity.length() > max_speed:
#		state.linear_velocity=state.linear_velocity.normalized() * max_speed
		#artificial stopping movement i.e not using physics
	if move_input.length() < 0.2:
		state.linear_velocity.x = lerp(state.linear_velocity.x,0,stop_speed)
		state.linear_velocity.z = lerp(state.linear_velocity.z,0,stop_speed)
		#push against floor to avoid sliding on "unreasonable" slopes
	if state.get_contact_count() > 0 and move_input.length()< 0.2:
		if is_on_floor and state.get_contact_local_normal(0).y < 0.9:
			add_central_force(-state.get_contact_local_normal(0)*10)

#mouse input
func _input(event):
	if is_network_master() && event is InputEventMouseMotion:
		mouse_input = event.relative;

sync func fire():
	if aimcast.is_colliding():
		print(aimcast.get_collision_point())
		var scene = get_tree().get_current_scene()
		
		var particle_instance = preload("res://scenes/BulletParticle.tscn").instance()
		scene.add_child(particle_instance)
		particle_instance.global_transform.origin = aimcast.get_collision_point()
		var collision_normal : Vector3 = aimcast.get_collision_normal()
		var current_normal : Vector3 = particle_instance.global_transform.basis.z
		particle_instance.global_rotate(collision_normal.cross(current_normal), -acos(collision_normal.dot(current_normal) / (collision_normal.length() * current_normal.length())))

sync func spawn_grenade(id):
	var scene = get_tree().get_current_scene()
	if not scene.has_node(str(id)):
		return
		
	var thrower_eyes = scene.get_node(str(id)).get_node('Body/Camera')
	var grenade_instance = preload("res://scenes/Grenade.tscn").instance()
	grenade_instance.name = "Grenade" + str(Network.object_name_index)
	
	Network.object_name_index += 1
	scene.add_child(grenade_instance)
	grenade_instance.global_transform.origin = thrower_eyes.global_transform.origin
	grenade_instance.linear_velocity = -thrower_eyes.global_transform.basis.z * 10

master func jump():
	var id = get_tree().get_rpc_sender_id()
	var scene = get_tree().get_current_scene()
	var player = scene.get_node(str(id))
	
	if player.feet.is_colliding():
		player.accel_multiplier = 0.1
		player.is_on_floor = false
		player.apply_central_impulse(Vector3.UP * jump_velocity)
		rpc('jumped', id)

puppet func jumped(id):
	var scene = get_tree().get_current_scene()
	var player = scene.get_node(str(id))
	
	if player.feet.is_colliding():
		player.accel_multiplier = 0.1
		player.is_on_floor = false
		player.apply_central_impulse(Vector3.UP * jump_velocity)

master func update_rotation(x, y):
	var id = get_tree().get_rpc_sender_id()
	var scene = get_tree().get_current_scene()
	var player = scene.get_node(str(id))
	
	player.get_node('Body/Camera').rotation_degrees.x = x
	player.get_node('Body').rotation_degrees.y = y
	rpc_unreliable('sync_rotation', id, x, y)

master func update_input(move_input):
	var id = get_tree().get_rpc_sender_id()
	var scene = get_tree().get_current_scene()
	var player = scene.get_node(str(id))
	
	player.move_input = move_input
	rpc_unreliable("sync_input", id, move_input)

puppet func sync_rotation(id, x, y):
	var scene = get_tree().get_current_scene()
	var player = scene.get_node(str(id))
	
	player.get_node('Body/Camera').rotation_degrees.x = x
	player.get_node('Body').rotation_degrees.y = y

puppet func sync_input(id, move_input):
	var scene = get_tree().get_current_scene()
	var player = scene.get_node(str(id))
	
	player.move_input = move_input

remote func sync_body(id, position, velocity, rotation):
	var scene = get_tree().get_current_scene()
	var player = scene.get_node(str(id))
	var body = player.get_node("Body")
	var eyes = body.get_node('Camera')
	
	var difference = position - player.global_transform.origin
	if difference.length() > 0.5:
		player.global_transform.origin = position
	
	difference = player.linear_velocity - velocity
	if difference.length() > 0:
		player.linear_velocity = velocity
	
	if abs(eyes.rotation_degrees.x - rotation.x) > 10:
		eyes.rotation_degrees.x = rotation.x
	
	if abs(body.rotation_degrees.y - rotation.y) > 10:
		body.rotation_degrees.y = rotation.y

func _on_NetworkSyncTimer_timeout():
	if get_tree().is_network_server():
		rpc_unreliable('sync_body', get_network_master(), global_transform.origin, linear_velocity, Vector2(eyes.rotation_degrees.x, body.rotation_degrees.y))
	else:
		$NetworkSyncTimer.stop()
