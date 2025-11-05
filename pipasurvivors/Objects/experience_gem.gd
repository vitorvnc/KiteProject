extends Area2D

@export var experience = 1

var spr_yellow = preload("res://resources/sprites/starExp-Sheet.png")
var spr_blue = preload("res://resources/sprites/starExpBlue-Sheet.png")
var spr_green = preload("res://resources/sprites/starExpGreen-Sheet.png")

var target = null
var speed = 0

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var sound = $snd_collected
@onready var animation = $AnimationPlayer

func _ready():
	print("ready do gem", animation)
	if experience <5:
		animation.play("blink")
		return
	elif experience < 25:
		sprite.texture = spr_blue
	else:
		sprite.texture = spr_yellow
	animation.play("blink")
	
func _physics_process(delta: float) -> void:
	if target != null:
		global_position = global_position.move_toward(target.global_position, speed)
		speed += 10*delta

func collect():
	sound.play()
	collision.call_deferred("set", "disabled", true)
	sprite.visible = false
	return experience


func _on_snd_collected_finished():
	queue_free()
