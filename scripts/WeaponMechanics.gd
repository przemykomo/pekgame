extends Reference

enum WeaponType {HITSCAN, THROWABLE}

var damage : int
var weapon_type
var mesh : PackedScene
var scene_to_spawn : PackedScene

func _init(damage : int, weapon_type, mesh : PackedScene, scene_to_spawn : PackedScene = null):
	self.damage = damage
	self.weapon_type = weapon_type
	self.mesh = mesh
	self.scene_to_spawn = scene_to_spawn

func use(player : RigidBody):
	match weapon_type:
		WeaponType.HITSCAN:
			player.gunshot_audio.play()
			if player.aimcast.is_colliding():
				var scene = player.get_tree().get_current_scene()
				
				var target = player.aimcast.get_collider()
				if target.is_in_group("players"):
					print("hit enemy " + str(damage))
					target.damage(damage)
				else:
					print("hit ground  " + str(damage))
					var bullet_decal = preload("res://scenes/BulletDecal.tscn").instance()
					target.add_child(bullet_decal)
					bullet_decal.global_transform.origin = player.aimcast.get_collision_point()
					bullet_decal.look_at(player.aimcast.get_collision_point() + player.aimcast.get_collision_normal(), Vector3.UP)
		WeaponType.THROWABLE:
			var scene = player.get_tree().get_current_scene()
	
			var grenade_instance = preload("res://scenes/Grenade.tscn").instance()
#			grenade_instance.name = "Grenade" + str(Network.object_name_index)
#
#			Network.object_name_index += 1
			scene.get_node("SyncBodies").add_child(grenade_instance)
			grenade_instance.global_transform.origin = player.eyes.global_transform.origin
			grenade_instance.linear_velocity = -player.eyes.global_transform.basis.z * 10
			
			player.weapon_mechanics = null
			if player.hand.get_child_count() > 0:
				player.hand.get_child(0).queue_free()
			
			player.throw_audio.play()

