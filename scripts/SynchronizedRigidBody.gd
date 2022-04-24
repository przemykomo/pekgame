extends RigidBody

func _ready():
	pass
	
puppet func sync_body(position, velocity):
	global_transform.origin = position
	linear_velocity = velocity

func _on_NetworkSyncTimer_timeout():
	if get_tree().is_network_server():
		rpc_unreliable("sync_body", global_transform.origin, linear_velocity)
	else:
		$NetworkSyncTimer.stop()
