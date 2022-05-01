extends RigidBody

var dropped = false

func _process(delta):
	if dropped:
		apply_impulse(transform.basis.z, -transform.basis.z * 10)
		dropped = false
