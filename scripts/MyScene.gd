extends Spatial

var player = preload("res://scenes/Player.tscn")

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	
	Global.connect("instance_player", self, "_instance_player")
	
	if get_tree().network_peer != null:
		Global.emit_signal("toggle_network_setup", false)

func _player_connected(id):
	print("Player " + str(id) + " has connected")
	_instance_player(id)

func _instance_player(id):
	var player_instance = player.instance()
	player_instance.set_network_master(id)
	player_instance.name = str(id)
	
	get_node("PlayerSync").add_child(player_instance)
	player_instance.global_transform.origin = Vector3(0, 5, 0)

func _player_disconnected(id):
	print("Player " + str(id) + " has disconnected")
	
	var player_sync = get_node("PlayerSync")
	
	if player_sync.has_node(str(id)):
		player_sync.get_node(str(id)).queue_free()
