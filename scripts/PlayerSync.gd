extends Timer

puppet func sync_body(name, position, velocity, rotation, health):
	var child = get_node(name)
	if child != null:
		var difference = position - child.global_transform.origin
		if difference.length() > 0.5:
			child.global_transform.origin = position
	
		difference = child.linear_velocity - velocity
		if difference.length() > 0:
			child.linear_velocity = velocity
		
		if !child.is_network_master():
			if abs(child.eyes.rotation_degrees.x - rotation.x) > 10:
				child.eyes.rotation_degrees.x = rotation.x
		
			if abs(child.body.rotation_degrees.y - rotation.y) > 10:
				child.body.rotation_degrees.y = rotation.y
		
		child.health = health

func _on_PlayerSync_timeout():
	for child in get_children():
		rpc_unreliable("sync_body", child.name, child.global_transform.origin, child.linear_velocity, Vector2(child.eyes.rotation_degrees.x, child.body.rotation_degrees.y), child.health)
