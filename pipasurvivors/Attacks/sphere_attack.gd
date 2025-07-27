extends Area2D

var level = 1
var hp = 1
var damage = 5
var target = Vector2.ZERO
var angle = Vector2.ZERO

# Propriedades exportáveis para fácil ajuste no editor
@export var base_damage: float = 5.0
@export var knockback_force: float = 200.0
@export var speed: float = 350.0
@export var lifetime: float = 3.0  # Tempo até destruir automaticamente
@export var attack_size: float = 1.0
@export var pierce_count: int = 1  # Quantos inimigos pode acertar antes de desaparecer

var current_damage: float
var current_knockback: float
var direction: Vector2 = Vector2.ZERO
var hit_enemies: Array[Node] = []

@onready var player = get_tree().get_first_node_in_group("player")
signal remove_from_array(object)

func setup(initial_position: Vector2, target_position: Vector2, weapon_data: WeaponData = null):
	global_position = initial_position
	#está repetindo pq o tutorial usava angle e eu usei direction (talvez trocar pra direction depois)
	angle = initial_position.direction_to(target_position)
	direction = initial_position.direction_to(target_position)
	rotation = angle.angle() + deg_to_rad(135)  # Ajuste visual
	
	if weapon_data:
		current_damage = weapon_data.base_damage
		current_knockback = weapon_data.knockback_force
		speed = weapon_data.speed if weapon_data.speed > 0 else speed
	else:
		current_damage = base_damage
		current_knockback = knockback_force
 	# Se for um ataque acolado, não precisa de física
	if weapon_data and weapon_data.is_child_attack:
		set_physics_process(false)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func enemy_hit(charge = 1):
	hp -= charge
	if hp <= 0:
		emit_signal("remove_from_array", self)
		queue_free()


func _on_timer_timeout() -> void:
	emit_signal("remove_from_array", self)
	queue_free()

func get_knockback_direction() -> Vector2:
	# Para whip attack, o knockback é sempre para frente do player
	return direction.normalized()
			
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and not hit_enemies.has(body):
		hit_enemies.append(body)
		# Aplica dano
		if body.has_method("take_damage"):
			body.take_damage(current_damage)
			
		# Aplica knockback
		if body.has_method("take_knockback"):
			var knockback_direction = get_knockback_direction()
			body.take_knockback(knockback_direction, current_knockback)
		# Verifica se deve desaparecer após acertar
		pierce_count -= 1
		if pierce_count <= 0:
			queue_free()

func enable_attack():
	# Reativa a detecção de colisão
	monitoring = true
	monitorable = true
#FUNCAO ANTIGA --IMPLEMENTAR DENTRO DOS INIMIGOS COMO ESTA NO METODO ACIMA (BODY ENTERED)
