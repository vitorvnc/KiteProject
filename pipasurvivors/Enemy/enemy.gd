extends CharacterBody2D

@export var hp = 15
@export var knockback_recovery = 10.5
@export var movement_speed = 80.0
@export var experience = 1
@export var enemy_damage = 10
var knockback = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var sprite = $Sprite2D
@onready var collisionEnemy = $CollisionEnemy
@onready var anim = $Sprite2D/AnimationPlayer

@onready var fogo_body = $FogoBody
@onready var animFire = $FogoBody/AnimationPlayerFire
@onready var spriteFire = $FogoBody/FogoSprite
@onready var snd_hit = $snd_hit
@onready var hitBox = $HitBox

var exp_gem = preload("res://Objects/experience_gem.tscn")

# Posição original do FogoBody quando não está flipado
var original_fire_position = Vector2(22, 1)
# Posição flipada do FogoBody
var flipped_fire_position = Vector2(-20, 1)

var death_anim = preload("res://Enemy/death_explosion.tscn")

signal remove_from_array(object)

func _ready():
		anim.play("walk")
		animFire.play("fogoExplode")
		hitBox.damage = enemy_damage


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
	var new_gem = exp_gem.instantiate()
	new_gem.global_position = global_position
	new_gem.experience = experience
	loot_base.call_deferred("add_child", new_gem)
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
	#print('entrou no hurtbox do enemy', damage, angle, knockback_force)
	take_damage(damage)
	take_knockback((angle), knockback_force)
