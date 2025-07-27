extends CharacterBody2D

@export var hp = 80.0
@export var movement_speed = 80.0

@export var rotation_speed = 4.5
@export var upper_limit: float = -20 #LIMITE SUPERIOR DA TELA
@export var lower_limit: float = 1300 #LIMITE INFERIOR DA TELA

@onready var walkTimer = get_node("%walkAnimationTimer")
@onready var sprite = $SpritePipa
@onready var collisionPipa = $CollisionPipa

var experience = 0
var experience_level = 1
var collected experience = 0

#ATTACK
@export var weapons_db: WeaponDatabase
@export var starting_weapons: Array[String] = ['whipatk', 'waveatk','sphereatk']  # IDs das armas iniciais
var active_attacks: Array[Node] = []
var available_weapons: Array[Dictionary] = []  # {data: WeaponData, timer: Timer}

@export var attack_spawn_point: Marker2D  # Ponto de spawn dos ataques
var target_enemy: Node2D = null

#enemyRelated
var enemy_close = []

@export var attack_cooldown: float = 5


func _ready():
	print("=== INICIALIZANDO ===")
	attack_spawn_point = $AttackSpawnPoint
	print("Spawn point:", attack_spawn_point)
		 # Debug do weapon_data
		
	var test_data = weapons_db.get_weapon_by_id("whipatk")
	if test_data:
		print("Teste WeaponData - ID:", test_data.id)
		print("Cena do ataque:", test_data.attack_scene)
	else:
		print("Erro: Não encontrou whipatk no DB")
		
	var weapon = load("res://Utility/weapons_db.tres::Resource_mqtek")
	print("Cooldown do novo arquivo: ", weapon.cooldown)
	
	if test_data:
		print("ID: ", test_data.id)
		print("Cooldown: ", test_data.cooldown)
		print("Caminho do Resource: ", test_data.resource_path)
	else:
		print("Arma não encontrada")
	load_starting_weapons()
	

#MOVIMENTO START
func _physics_process(delta: float) -> void:
	var y_altura = global_position.y
	handle_rotation()
	movement()
	if y_altura < upper_limit or y_altura > lower_limit:
		print("MORREU")
		
	var collision = move_and_collide(velocity * delta)
	update_attack_directions()
	# Atualiza o inimigo alvo periodicamente
	if Engine.get_frames_drawn() % 30 == 0:  # A cada 30 frames
		update_target_enemy()

func handle_rotation():
	var rotation_direction = Input.get_action_strength("right") - Input.get_action_strength("left")
	rotation += rotation_direction * rotation_speed * get_physics_process_delta_time()
	
func movement():
	var direction = Vector2.UP.rotated(rotation)
	velocity = direction * movement_speed
	
	if walkTimer.is_stopped():
		if sprite.rotation >= 0:
			sprite.rotation = -0.01
			sprite.rotation = -0.02
		else:
			sprite.rotation = 0.01
			sprite.rotation = 0.02
		walkTimer.start()
	move_and_slide()
#MOVIMENTO END

func killPlayer():
	pass
	
func _on_hurt_box_hurt(damage: Variant, _angle, _knockback) -> void:
	hp-= damage

#ATTACK AREA
# Atualiza a direção dos ataques (se necessário)
func update_attack_directions():
	# Filtra ataques que ainda estão na árvore de cena
	active_attacks = active_attacks.filter(func(attack): return is_instance_valid(attack))
	
	for attack in active_attacks:
		if attack.has_method("set_direction"):
			attack.set_direction(Vector2.UP.rotated(rotation))
			
# Ativa/desativa todos os ataques
func set_attacks_active(active: bool):
	for attack in active_attacks:
		attack.set_process(active)
		attack.set_physics_process(active)
		attack.monitoring = active
		attack.monitorable = active
		
func load_starting_weapons():
	for weapon_id in starting_weapons:
		
		var weapon_data = weapons_db.get_weapon_by_id(weapon_id)
		print('vai pegar wd pra entrar no add: ', weapon_data)
		if weapon_data:
			add_weapon(weapon_data)

func add_weapon(weapon_data: WeaponData):
	print('entrou no add weapon', weapon_data)
	if not weapon_data or not weapon_data.attack_scene:
		return
		
	var timer = Timer.new()
	timer.name = "Timer_" + weapon_data.id
	timer.wait_time = weapon_data.cooldown
	timer.one_shot = false
	timer.autostart = false
	
	timer.timeout.connect(
		func():
			#print("Timer disparado para:", weapon_data.id)
			_spawn_weapon_attack(weapon_data.id),
		CONNECT_PERSIST
	)
	
	# Adiciona à árvore e inicia
	add_child(timer)
	timer.start()
	
	available_weapons.append({
		"data": weapon_data,
		"timer": timer
	})
	
	print("Timer criado para ", weapon_data.id, "com cooldown ", weapon_data.cooldown)
	
func upgrade_weapon(weapon_id: String):
	var weapon_data = weapons_db.get_weapon_by_id(weapon_id)
	if not weapon_data:
		return
		
	# Encontra a arma existente
	var weapon_index = -1
	for i in range(available_weapons.size()):
		if available_weapons[i]["data"].id.begins_with(weapon_id.split("_")[0]):
			weapon_index = i
			break
	
	# Se encontrou, remove a versão antiga
	if weapon_index >= 0:
		available_weapons[weapon_index]["timer"].queue_free()
		available_weapons.remove_at(weapon_index)
		
	# Adiciona a nova versão
	add_weapon(weapon_data)

# Para adicionar uma nova arma
func on_pickup_item(weapon_id: String):
	var weapon_data = weapons_db.get_weapon_by_id(weapon_id)
	if weapon_data:
		if weapon_data.level == 1:
			add_weapon(weapon_data)
		else:
			upgrade_weapon(weapon_id)

func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else:
		return Vector2.UP


func _on_enemy_detection_area_body_entered(body: Node2D) -> void:
	if not enemy_close.has(body):
		enemy_close.append(body)


func _on_enemy_detection_area_body_exited(body: Node2D) -> void:
	if enemy_close.has(body):
		enemy_close.erase(body)



#Attack NOVO START
func update_target_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() > 0:
		 # Encontra o inimigo mais próximo
		var closest_enemy = null
		var closest_distance = INF
		
		for enemy in enemies:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = enemy
				
		target_enemy = closest_enemy
		
func _spawn_weapon_attack(weapon_id: String):
	var weapon_data = weapons_db.get_weapon_by_id(weapon_id)
	if not weapon_data or not attack_spawn_point:
		return
	
	if not attack_spawn_point:
		return
	
	var attack_instance = weapon_data.attack_scene.instantiate() 
	# Decide se é child do player ou da cena
	
	if weapon_data.is_child_attack:
		add_child(attack_instance)  # Anexa ao player
		if attack_instance.has_method("setup"):
			attack_instance.show_behind_parent = true
			attack_instance.setup(
				Vector2.ZERO,  # Posição será ajustada no whip_attack.gd
				Vector2.ZERO, 
				weapon_data
			)
	else:
		get_parent().add_child(attack_instance)  # Anexa à cena
		var target_pos = target_enemy.global_position if target_enemy else Vector2.RIGHT.rotated(rotation)
		if attack_instance.has_method("setup"):
			attack_instance.setup(attack_spawn_point.global_position, target_pos, weapon_data)
		
#Attack NOVO END
