extends Reference

enum WeaponType {HITSCAN, THROWABLE}

var damage : int
var weapon_type
var mesh : PackedScene

func _init(damage : int, weapon_type, mesh : PackedScene):
	self.damage = damage
	self.weapon_type = weapon_type
	self.mesh = mesh

func use(player):
	if player.aimcast.is_colliding():
		var scene = player.get_tree().get_current_scene()
		
		var target = player.aimcast.get_collider()
		if target.is_in_group("players"):
			print("hit enemy " + str(damage))
		else:
			print("hit ground  " + str(damage))
			var bullet_decal = preload("res://scenes/BulletDecal.tscn").instance()
			target.add_child(bullet_decal)
			bullet_decal.global_transform.origin = player.aimcast.get_collision_point()
			bullet_decal.look_at(player.aimcast.get_collision_point() + player.aimcast.get_collision_normal(), Vector3.UP)
