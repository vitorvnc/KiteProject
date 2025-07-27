extends CharacterBody2D

@export var hp = 15
@export var knockback_recovery = 10.5
@export var movement_speed = 100.0
var knockback = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $Sprite2D
@onready var collisionEnemy = $CollisionEnemy
@onready var anim = $AnimationPlayer

@onready var fogo_body = $FogoBody
@onready var animFire = $FogoBody/AnimationPlayerFire
@onready var spriteFire = $FogoBody/FogoSprite
@onready var snd_hit = $snd_hit

# Posição original do FogoBody quando não está flipado
var original_fire_position = Vector2(24, -2)
# Posição flipada do FogoBody
var flipped_fire_position = Vector2(-24, -2)

var death_anim = preload("res://Enemy/death_explosion.tscn")

signal remove_from_array(object)

func _ready():
	anim.play("walk")
	animFire.play("fogoExplode")

func _physics_process(delta: float) -> void:
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	var direction = global_position.direction_to(player.global_position)
	velocity = direction*movement_speed
	velocity += knockback
	move_and_slide()
	
	if direction.x > 0.1 and not sprite.flip_h:
		sprite.flip_h = true
		spriteFire.position = flipped_fire_position
		spriteFire.flip_v = true
	elif direction.x < -0.1 and sprite.flip_h:
		sprite.flip_h = false
		spriteFire.position = original_fire_position
		spriteFire.flip_v = false

func death():
	emit_signal("remove_from_array", self)
	var enemy_death = death_anim.instantiate()
	enemy_death.scale = sprite.scale
	enemy_death.global_position = global_position
	get_parent().call_deferred("add_child", enemy_death)
	queue_free()
	
func take_damage(amount: float):
	hp -= amount
	if hp <= 0:
		death()
	else:
		snd_hit.play()

func take_knockback(direction: Vector2, force: float):
	knockback = direction * force	

func _on_hurt_box_hurt(damage, angle, knockback_force):
	print('entrou no hurtbox do enemy', damage, angle, knockback_force)
	take_damage(damage)
	take_knockback((angle), knockback_force)
