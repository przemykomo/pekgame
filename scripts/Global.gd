extends Node

const WeaponMechanics : = preload("res://scripts/WeaponMechanics.gd")

signal instance_player(id)
signal toggle_network_setup(toggle)

var weapons = [
	WeaponMechanics.new(1, WeaponMechanics.WeaponType.HITSCAN, preload("res://scenes/weapon_models/Pistol.tscn")),
	WeaponMechanics.new(2, WeaponMechanics.WeaponType.HITSCAN, preload("res://scenes/weapon_models/BlueGun.tscn")),
	WeaponMechanics.new(3, WeaponMechanics.WeaponType.HITSCAN, preload("res://scenes/weapon_models/GreenGun.tscn")),
	WeaponMechanics.new(0, WeaponMechanics.WeaponType.THROWABLE, preload("res://scenes/weapon_models/GrenadeMesh.tscn"), preload("res://scenes/Grenade.tscn"))
]

func _ready():
	randomize()
