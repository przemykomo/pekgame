extends RigidBody

export var jump_velocity = 5
export var acceleration = 5
var accel_multiplier = 1.0
export var speed = 25
export var max_speed = 10
export (float, 0.01,1.0) var stop_speed = 0.1

var velocity=Vector3()

var mouse_input = Vector2()
onready var eyes = $Body/Camera
onready var body = $Body
onready var feet = $Feet
export var view_sensitivity = 30.0
var is_on_floor = false
var move_input

func _ready():
	if is_network_master():
		eyes.current = true
		linear_damp = 1.0
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	if is_network_master():
		#reset friction to zero to avoid sticking to walk when velocity is applied
	#	if friction >= 0: friction = 0
		is_on_floor = false
		move_input = Vector2.ZERO
		var dir = Vector3()
		#movement input
		move_input = Input.get_vector("left","right","down","up")
		dir += move_input.x*body.global_transform.basis.x;
		dir -= move_input.y*body.global_transform.basis.z;
		velocity = lerp(velocity,dir*speed,acceleration*accel_multiplier*delta)
		add_central_force(velocity)
		if feet.is_colliding():
			is_on_floor = true
	#		friction = 1.0
			accel_multiplier = 1.0
		if Input.is_action_just_pressed("jump") and is_on_floor:
			accel_multiplier = 0.1
			is_on_floor = false
			apply_central_impulse(Vector3.UP * jump_velocity)
		#view and rotation
		eyes.rotation_degrees.x -= mouse_input.y * view_sensitivity * delta;
		eyes.rotation_degrees.x = clamp(eyes.rotation_degrees.x,-80,80)
		body.rotation_degrees.y -= mouse_input.x * view_sensitivity * delta;
		mouse_input = Vector2.ZERO
		
		if Input.is_action_just_pressed("throw"):
			rpc("spawn_grenade", get_tree().get_network_unique_id())

func _integrate_forces(state):
	if is_network_master():
		#limit max speed
		if state.linear_velocity.length()>max_speed:
			state.linear_velocity=state.linear_velocity.normalized()*max_speed
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

sync func spawn_grenade(id):
	var grenade_instance = preload("res://scenes/Grenade.tscn").instance()
	grenade_instance.name = "Grenade" + str(Network.object_name_index)
	Network.object_name_index += 1
	get_tree().get_current_scene().add_child(grenade_instance)
	grenade_instance.global_transform.origin = eyes.global_transform.origin
	grenade_instance.linear_velocity = -eyes.global_transform.basis.z * 10

puppet func sync_body(position, velocity, rotation):
	global_transform.origin = position
	linear_velocity = velocity
	eyes.rotation_degrees.x = rotation.x
	body.rotation_degrees.y = rotation.y

func _on_NetworkSyncTimer_timeout():
	if is_network_master():
		rpc_unreliable("sync_body", global_transform.origin, linear_velocity, Vector2(eyes.rotation_degrees.x, body.rotation_degrees.y))
	else:
		$NetworkSyncTimer.stop()
