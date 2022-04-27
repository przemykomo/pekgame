extends Timer

func _on_ExplosionTimer_timeout():
	get_node("../CollisionShape").queue_free()
	get_node("../MeshInstance").queue_free()
	get_node("../Particles").emitting = true
	for physicsBody in get_node("../ExplosionArea").get_overlapping_bodies():
		if physicsBody != get_parent() && physicsBody is RigidBody:
			var distance = physicsBody.global_transform.origin + Vector3(0, 0.5, 0) - get_parent().global_transform.origin
			physicsBody.apply_central_impulse(distance.normalized() * (1 - distance.length() / 7) * 50)
	
	yield(get_tree().create_timer(1), "timeout")
	get_parent().queue_free()
