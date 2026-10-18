# res://Utility/game_state.gd
extends Node

var selected_character: CharacterData = null
var selected_weapon_id: String = ""

func get_starting_weapon() -> String:
	if selected_character:
		return selected_character.starting_weapon_id
	return "sphereatk_1"  # fallback
