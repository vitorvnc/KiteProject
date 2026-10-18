extends Resource
class_name WeaponDatabase

@export var weapons: Array[WeaponData] = []

func get_weapon_by_id(id: String) -> WeaponData:
	for weapon in weapons:
		if weapon.id == id:
			return weapon
	return null

func get_prerequisites(id: String) -> Array[WeaponData]:
	var weapon = get_weapon_by_id(id)
	if weapon == null:
		return []
	
	var prereqs: Array[WeaponData] = []
	for prereq_id in weapon.prerequisite_ids:
		var prereq = get_weapon_by_id(prereq_id)
		if prereq:
			prereqs.append(prereq)
	return prereqs
