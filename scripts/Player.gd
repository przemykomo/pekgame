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
onready var reach = $Body/Camera/Reach
onready var hand = $Body/Camera/Hand
onready var body = $Body
onready var feet = $Feet
onready var anim_play = $Body/Camera/AnimationPlayer
onready var throw_audio = $ThrowAudio
onready var gunshot_audio = $GunshotAudio
export var view_sensitivity = 60.0
export var is_on_floor = false
var old_move_input = Vector2.ZERO
export var move_input = Vector2.ZERO

var weapon_mechanics
var health : int = 100 setget set_health

onready var pause_menu = get_tree().get_current_scene().get_node("PauseMenu")
var paused = false

func _ready():
	if is_network_master():
		eyes.current = true
		linear_damp = 1.0
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	if Input.is_action_just_pressed("menu"):
		if paused:
			pause_menu.visible = false
			paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			pause_menu.visible = true
			paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if is_network_master() && !paused && health > 0:
		if Input.is_action_just_pressed("interract") && reach.is_colliding():
			rpc("grab_weapon", reach.get_collider().get_path())
		if Input.is_action_just_pressed("debug"):
			rpc("debug_action", randi() % Global.weapons.size())

remotesync func debug_action(weapon_id):
	var weapon_instance = preload("res://scenes/Weapon.tscn").instance()
	weapon_instance.weapon_mechanics = Global.weapons[weapon_id]
	get_tree().get_current_scene().get_node("SyncBodies").add_child(weapon_instance)
	weapon_instance.global_transform.origin = Vector3(0, 10, 0)

remotesync func grab_weapon(path):
	var collider = get_tree().get_current_scene().get_node(path)
	
	if collider != null && collider.is_in_group("dropped_weapons"):
		if weapon_mechanics != null:
			var weapon_to_drop = preload("res://scenes/Weapon.tscn").instance()
			weapon_to_drop.dropped = true
			weapon_to_drop.weapon_mechanics = weapon_mechanics
			get_tree().get_current_scene().get_node("SyncBodies").add_child(weapon_to_drop)
			weapon_to_drop.global_transform = hand.global_transform
			if hand.get_child_count() > 0:
				hand.get_child(0).queue_free()
		weapon_mechanics = collider.weapon_mechanics
		collider.queue_free()
		hand.add_child(weapon_mechanics.mesh.instance())

func _physics_process(delta):
	if feet.is_colliding():
		is_on_floor = true
		accel_multiplier = 1.0
		
	if is_network_master():
		old_move_input = move_input
		if paused:
			move_input = Vector2.ZERO
		else:
			move_input = Input.get_vector("left","right","down","up")
		if old_move_input != move_input:
			rpc('update_input', move_input)
		
		if !paused && health > 0:
			if move_input != Vector2.ZERO:
				anim_play.play("Bobbing")
			
			if mouse_input.length() > 0:
				eyes.rotation_degrees.x -= mouse_input.y * view_sensitivity * delta;
				eyes.rotation_degrees.x = clamp(eyes.rotation_degrees.x,-80,80)
				body.rotation_degrees.y -= mouse_input.x * view_sensitivity * delta;
				mouse_input = Vector2.ZERO
				rpc_unreliable('sync_rotation', eyes.rotation_degrees.x, body.rotation_degrees.y)
			
			if Input.is_action_just_pressed("jump"):
				accel_multiplier = 0.1
				rpc('jump')
			
			if Input.is_action_just_pressed("use_weapon"):
				rpc('use_weapon')

func _integrate_forces(state):
	if state.linear_velocity.length() < max_speed:
		var dir = Vector3()
		dir += move_input.x * body.global_transform.basis.x;
		dir -= move_input.y * body.global_transform.basis.z;
		velocity = lerp(velocity, dir * speed, acceleration * accel_multiplier / 60)
		add_central_force(velocity)
		
	#artificial stopping movement i.e not using physics
	if move_input.length() < 0.2:
		state.linear_velocity.x = lerp(state.linear_velocity.x, 0, stop_speed)
		state.linear_velocity.z = lerp(state.linear_velocity.z, 0, stop_speed)
		#push against floor to avoid sliding on "unreasonable" slopes
	if state.get_contact_count() > 0 and move_input.length() <  0.2:
		if is_on_floor and state.get_contact_local_normal(0).y < 0.9:
			add_central_force(-state.get_contact_local_normal(0) * 10)

#mouse input
func _input(event):
	if is_network_master() && !paused && event is InputEventMouseMotion:
		mouse_input = event.relative;

remotesync func use_weapon():
	if weapon_mechanics != null:
		weapon_mechanics.use(self)

master func jump():
	if feet.is_colliding():
		accel_multiplier = 0.1
		is_on_floor = false
		apply_central_impulse(Vector3.UP * jump_velocity)
		rpc('jumped')

puppet func jumped():
	if feet.is_colliding():
		accel_multiplier = 0.1
		is_on_floor = false
		apply_central_impulse(Vector3.UP * jump_velocity)

master func update_input(move_input):
	self.move_input = move_input
	rpc_unreliable("sync_input", move_input)

puppet func sync_rotation(x, y):
	eyes.rotation_degrees.x = x
	body.rotation_degrees.y = y

puppet func sync_input(move_input):
	self.move_input = move_input

func damage(amount : int):
	set_health(health - amount)

func set_health(value : int):
	health = value
	if is_network_master():
		get_tree().get_current_scene().get_node("HUD/Label").text = str(health)
	if health <= 0:
		visible = false
		if is_network_master():
			var parent = get_parent()
			if parent.get_child_count() > 1:
				for child in parent.get_children():
					if child.health > 0:
						child.eyes.make_current()
