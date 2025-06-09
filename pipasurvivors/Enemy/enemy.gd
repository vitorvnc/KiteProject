extends CharacterBody2D

@export var hp = 15
@export var movement_speed = 50.0
@export var knockback_recovery = 3.5
@export var enemy_damage = 1
var knockback = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $Sprite2D
@onready var collisionEnemy = $CollisionEnemy
@onready var anim = $AnimationPlayer

@onready var fogo_body = $FogoBody
@onready var animFire = $FogoBody/AnimationPlayerFire
@onready var spriteFire = $FogoBody/FogoSprite


# Posição original do FogoBody quando não está flipado
var original_fire_position = Vector2(24, -2)
# Posição flipada do FogoBody
var flipped_fire_position = Vector2(-24, -2)

func _ready():
	anim.play("walk")
	animFire.play("fogoExplode")

func _physics_process(delta: float) -> void:
	var direction = global_position.direction_to(player.global_position)
	velocity = direction*movement_speed
	move_and_slide()
	
	if direction.x > 0.1 and not sprite.flip_h:
		sprite.flip_h = true
		spriteFire.position = flipped_fire_position
		spriteFire.flip_v = true
	elif direction.x < -0.1 and sprite.flip_h:
		sprite.flip_h = false
		spriteFire.position = original_fire_position
		spriteFire.flip_v = false
