extends Node

const WeaponMechanics : = preload("res://scripts/WeaponMechanics.gd")

signal instance_player(id)
signal toggle_network_setup(toggle)

var weapons = {
	"gun1": WeaponMechanics.new(5, WeaponMechanics.WeaponType.HITSCAN),
	"gun2": WeaponMechanics.new(10, WeaponMechanics.WeaponType.HITSCAN)
}
