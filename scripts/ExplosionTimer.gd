extends Timer

func _on_ExplosionTimer_timeout():
	get_node("../Particles").emitting = true
	for physicsBody in get_node("../ExplosionArea").get_overlapping_bodies():
		if physicsBody != get_parent() && physicsBody is RigidBody:
			var distance = physicsBody.global_transform.origin + Vector3(0, 0.5, 0) - get_parent().global_transform.origin
			physicsBody.apply_central_impulse(distance.normalized() * (1 - distance.length() / 7) * 50)
