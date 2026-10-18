# res://Databases/character_database.gd
extends Resource
class_name CharacterDatabase

@export var characters: Array[CharacterData] = []

func get_character_by_id(character_id: String) -> CharacterData:
	for character in characters:
		if character.id == character_id:
			return character
	return null

func get_character_by_index(index: int) -> CharacterData:
	if index >= 0 and index < characters.size():
		return characters[index]
	return null

func get_total_characters() -> int:
	return characters.size()
