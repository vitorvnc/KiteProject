extends ColorRect

const ICON_PATH = "res://resources/Icons/"
@export var weapons_db: WeaponDatabase

@onready var lblName = $lbl_name
@onready var lblDescription = $lbl_description
@onready var lblLevel = $lbl_level
@onready var itemIcon = $ColorRect/ItemIcon

var mouse_over = false
var item = null
@onready var player = get_tree().get_first_node_in_group("player")

signal selected_upgrade(upgrade)

func _ready():
	connect("selected_upgrade", Callable(player, "upgrade_character"))
	if item == null:
		item = weapons_db.get_weapon_by_id("glue")
	lblName.text = item.display_name
	lblDescription.text = item.description
	lblLevel.text = str(item.level)
	itemIcon.texture = load(item.icon)

func _input(event):
	if event.is_action("click"):
		if mouse_over:
			emit_signal("selected_upgrade", item)

func _on_mouse_entered() -> void:
	mouse_over = true


func _on_mouse_exited() -> void:
	mouse_over = false
