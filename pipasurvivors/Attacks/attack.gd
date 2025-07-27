extends Area2D
class_name BaseAttack

var weapon_data: WeaponData
var current_level: int = 1
var hit_enemies: Array[Node] = []

func setup(data: WeaponData, level: int = 1):
	weapon_data = data
	current_level = level
	
	# Configura com base no nível
	var stats = weapon_data.get_level_stats(current_level)
	scale = Vector2(stats.get("size", 1.0), stats.get("size", 1.0))
	
	# Configura timer
	$Timer.wait_time = stats.get("lifetime", 2.0)
	$Timer.start()

func get_damage() -> float:
	return weapon_data.get_level_stats(current_level).get("damage", 5.0)

func get_knockback() -> float:
	return weapon_data.get_level_stats(current_level).get("knockback", 100.0)

func _on_body_entered(body: Node2D):
	if body.is_in_group("enemy") && !hit_enemies.has(body):
		hit_enemies.append(body)
		if body.has_method("take_damage"):
			body.take_damage(get_damage())
		if body.has_method("take_knockback"):
			var dir = (body.global_position - global_position).normalized()
			body.take_knockback(dir * get_knockback())

func _on_timer_timeout():
	queue_free()
