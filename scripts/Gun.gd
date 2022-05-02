extends RigidBody

const WeaponMechanics : = preload("res://scripts/WeaponMechanics.gd")

var dropped = false
var weapon_mechanics : WeaponMechanics

func _ready():
	if weapon_mechanics != null:
		add_child(weapon_mechanics.mesh.instance())

func _process(delta):
	if dropped:
		apply_impulse(transform.basis.z, -transform.basis.z * 10)
		dropped = false
