extends Control

var level = "res://Levels/first_level.tscn"
@onready var charSelectPanel = get_node("%CharSelect")

#Menu Character Select
@onready var portraitTexture = get_node("%CharPortrait")
@onready var lblCharacterName = get_node("%lblCharacterName")
@onready var lblPower = get_node("%lblPower")
@onready var lblKite = get_node("%lblKite")
@onready var btnPrev = get_node("%btn_prev")
@onready var btnNext = get_node("%btn_next")
@onready var btnChoose = get_node("%btn_choose")
@onready var btnBack = get_node("%btn_back")

#Database Character Select
var char_db: CharacterDatabase = load("res://Databases/characters_db.tres")
var current_character_index: int = 0
var selected_character: CharacterData = null

func _ready():
	# Carrega o primeiro personagem
	if char_db and char_db.get_total_characters() > 0:
		update_character_display()
	else:
		push_warning("characters_db.tres não foi carregado ou está vazio!")

func _on_btn_play_click_end() -> void:
	var tween = charSelectPanel.create_tween()
	tween.tween_property(charSelectPanel, "position", Vector2(100, 200), 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	charSelectPanel.visible = true
	
	update_character_display()

func _on_btn_exit_click_end() -> void:
	get_tree().quit()

func _on_btn_prev_pressed():
	if not char_db or char_db.get_total_characters() == 0:
		return
	
	current_character_index -= 1
	if current_character_index < 0:
		current_character_index = char_db.get_total_characters() - 1
	
	update_character_display()

func _on_btn_next_pressed():
	if not char_db or char_db.get_total_characters() == 0:
		return
	
	current_character_index += 1
	if current_character_index >= char_db.get_total_characters():
		current_character_index = 0
	
	update_character_display()

func update_character_display():
	if not char_db:
		push_warning("char_db não configurado!")
		return
	
	selected_character = char_db.get_character_by_index(current_character_index)
	
	if not selected_character:
		push_warning("Nenhum personagem no índice: ", current_character_index)
		return
	
	# Atualiza a foto
	if portraitTexture and selected_character.portrait:
		portraitTexture.texture = selected_character.portrait
	
	# Atualiza o nome
	if lblCharacterName:
		lblCharacterName.text = selected_character.display_name
	if lblPower:
		lblPower.text = "Power: " + selected_character.power_description
	if lblKite:
		lblKite.text = "Kite: " + selected_character.kite_description

func _on_btn_choose_pressed():
	if not selected_character:
		push_warning("Nenhum personagem selecionado!")
		return
	
	GameState.selected_character = selected_character
	get_tree().change_scene_to_file(level)

func _on_btn_back_pressed():
	var tween = charSelectPanel.create_tween()
	tween.tween_property(charSelectPanel, "position", Vector2(800, 500), 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	await tween.finished
	charSelectPanel.visible = false
