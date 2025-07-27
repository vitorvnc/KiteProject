extends Area2D

var level = 1
var hp = 100
var damage = 5
var target = Vector2.ZERO
var angle = Vector2.ZERO

# Propriedades exportáveis para fácil ajuste no editor
@export var base_damage: float = 5.0
@export var knockback_force: float = 800.0
@export var speed: float = 350.0
@export var lifetime: float = 0.0  # Tempo até destruir automaticamente
@export var attack_size: float = 1.0
@export var pierce_count: int = 1  # Quantos inimigos pode acertar antes de desaparecer

var current_damage: float
var current_knockback: float
var direction: Vector2 = Vector2.ZERO
var hit_enemies: Array[Node] = []

@export var offset_position: Vector2 = Vector2(0, 0)  # Ajuste conforme necessário
var follow_parent: bool = true

@onready var anim = $AnimationPlayer

@onready var player = get_tree().get_first_node_in_group("player")
signal remove_from_array(object)

func setup(initial_position: Vector2, target_position: Vector2, weapon_data: WeaponData = null):
	z_index = 1
	if weapon_data:
		current_damage = weapon_data.base_damage
		current_knockback = weapon_data.knockback_force
		
	# Usa a posição do Marker2D se existir
	#print("Parent node: ", get_parent().name if get_parent() else "Nenhum")
	var whip_pos = get_parent().get_node_or_null("WhipPosition")
	if whip_pos:
		#print('whip position: ', whip_pos.position)
		position = whip_pos.position
	else:
		position = offset_position
		
	 #Garante que está na rotação correta
	rotation = 0  # A rotação será controlada pelo _physics_process
	
	# Se for um ataque acolado, não precisa de física
	if weapon_data and weapon_data.is_child_attack:
		follow_parent = true
		set_physics_process(false)
	else:
		follow_parent = false
	
func _ready():
	anim.play("slash_test")
	
func _physics_process(delta):
	if follow_parent:
		# Segue a rotação do parent (player)
		global_rotation = get_parent().global_rotation
		# Opcional: ajuste fino da posição baseado na rotação
		var rotated_offset = offset_position.rotated(get_parent().rotation)
		position = rotated_offset

func enemy_hit(charge = 1):
	print('enemy hit dentro da whip')
	hp -= charge
	if hp <= 0:
		emit_signal("remove_from_array", self)
		queue_free()
		
func get_knockback_direction() -> Vector2:
	# Para whip attack, o knockback é sempre para frente do player
	return Vector2.UP.rotated(get_parent().rotation)
	
func _on_body_entered(body: Node2D) -> void:
	print('entrou whip body')
	if body.is_in_group("enemy") and not hit_enemies.has(body):
		hit_enemies.append(body)
		# Aplica dano
		if body.has_method("take_damage"):
			body.take_damage(current_damage)
			
		# Aplica knockback
		if body.has_method("take_knockback"):
			var knockback_direction = get_knockback_direction()
			body.take_knockback(knockback_direction, current_knockback)
			
		if has_method("enemy_hit"):
			enemy_hit(1)
#FUNCAO ANTIGA --IMPLEMENTAR DENTRO DOS INIMIGOS COMO ESTA NO METODO ACIMA (BODY ENTERED)

func enable_attack():
	# Reativa a detecção de colisão
	monitoring = true
	monitorable = true
	# Reinicia a animação se necessário
	if $AnimationPlayer.has_animation("slash_test"):
		$AnimationPlayer.play("slash_test")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "slash_test":
		queue_free()
