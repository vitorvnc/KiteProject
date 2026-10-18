# res://Databases/character_data.gd
extends Resource
class_name CharacterData

@export var id: String = ""
@export var display_name: String = ""
@export var kite_description: String = ""
@export var power_description: String = ""
@export var portrait: Texture2D  # Foto do personagem
@export var pipa_sprite_path: String = ""
@export var starting_weapon_id: String = ""  # ID da arma inicial (ex: "sphereatk_1")
@export var starting_hp: float = 80.0
@export var starting_speed: float = 50.0
@export var starting_rotation_speed: float = 4.5
@export var preview_scene: PackedScene  # Opcional: cena de preview animada
