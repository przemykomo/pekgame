extends Timer

puppet func sync_body(name, position, velocity, rotation):
	var child = get_node(name)
	if child != null:
		child.global_transform.origin = position
		child.linear_velocity = velocity
		child.rotation = rotation

func _on_SyncBodies_timeout():
	for child in get_children():
		rpc_unreliable("sync_body", child.name, child.global_transform.origin, child.linear_velocity, child.rotation)
