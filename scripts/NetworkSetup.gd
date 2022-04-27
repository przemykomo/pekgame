extends Control

func _ready():
	Global.connect("toggle_network_setup", self, "_toggle_network_setup")

func _on_IpAddress_text_changed(new_text):
	Network.ip_address = new_text

func _on_Host_pressed():
	Network.create_server()
	hide()
	get_tree().get_current_scene().get_node("HUD").visible = true
	
	# create a player instance for local (hosting) player
	Global.emit_signal("instance_player", get_tree().get_network_unique_id())

func _on_Join_pressed():
	Network.join_server()
	hide()
	get_tree().get_current_scene().get_node("HUD").visible = true
	
	# create a player instance for local (joining) player
	Global.emit_signal("instance_player", get_tree().get_network_unique_id())

func _toggle_network_setup(toggle):
	visible = toggle
