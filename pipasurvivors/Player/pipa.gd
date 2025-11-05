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
var collected_experience = 0

#GUI
@onready var expBar = get_node("%ExperienceBar")
@onready var lblLevel = get_node("%lbl_level")
@onready var levelPanel = get_node("%LevelUp")
@onready var upgradeOptions = get_node("%UpgradeOptions")
@onready var itemOptions = preload("res://Utility/item_option.tscn")
@onready var sndLevelUp = get_node("%snd_levelup")

#ATTACK E WEAPONS
@export var attack_spawn_point: Marker2D  # Ponto de spawn dos ataques Whip
@export var weapons_db: WeaponDatabase
@export var starting_weapons: Array[Dictionary] = [  # IDs e levels das armas iniciais
	{'id': 'sphereatk_1', 'level': 1}
]
var active_attacks: Array[Node] = []
var collected_weapons: Array[Dictionary] = []  # {data: WeaponData, level: x, timer: Timer}

var collectedIdsCompareStringHist: Array[String] = []

#UPGRADES
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var speel_size = 0
var additional_attacks = 0

#ENEMY
var enemy_close = []
var target_enemy: Node2D = null




func _ready():
	set_expbar(experience, calculate_experiencecap())
	attack_spawn_point = $AttackSpawnPoint
	var weapon = load("res://Utility/weapons_db.tres::Resource_mqtek")

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
	for i in starting_weapons:
		var weapon_id = i['id']
		var weapon_data = weapons_db.get_weapon_by_id(weapon_id)
		#print('vai pegar wd pra entrar no add: ', weapon_data)
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
	
	collected_weapons.append({
		"data": weapon_data,
		"timer": timer
	})
	
	#print("Timer criado para ", weapon_data.id, "com cooldown ", weapon_data.cooldown)
	
func upgrade_weapon(weapon_id: String):
	var weapon_data = weapons_db.get_weapon_by_id(weapon_id)
	if not weapon_data:
		return
		
	# Encontra a arma existente
	var weapon_index = -1
	for i in range(collected_weapons.size()):
		if collected_weapons[i]["data"].id.begins_with(weapon_id.split("_")[0]):
			weapon_index = i
			break
	
	# Se encontrou, remove a versão antiga
	if weapon_index >= 0:
		collected_weapons[weapon_index]["timer"].queue_free()
		collected_weapons.remove_at(weapon_index)
		
	# Adiciona a nova versão
	add_weapon(weapon_data)

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


func _on_grab_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("loot"):
		area.target = self


func _on_collect_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)

func calculate_experience(gem_exp):
	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp
	if experience + collected_experience >= exp_required: #level up
		collected_experience -= exp_required-experience 
		experience_level += 1
		experience = 0
		exp_required = calculate_experiencecap()
		levelup()
		#calculate_experience(0)
	else:
		experience += collected_experience
		collected_experience = 0
	
	set_expbar(experience, exp_required)
		
func calculate_experiencecap():
	var exp_cap = experience_level
	if experience_level < 20:
		exp_cap = experience_level*5
	elif experience_level <40:
		exp_cap = 95 * (experience_level-19)*8
	else:
		exp_cap = 255 + (experience_level-39)*12
	return exp_cap

func set_expbar(set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value
	
func levelup():
	sndLevelUp.play()
	lblLevel.text = str("Level: ", experience_level)
	var tween = levelPanel.create_tween()
	tween.tween_property(levelPanel, "position", Vector2(260,500), 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelPanel.visible = true
	var options = 0
	var optionsmax = 3
	while options < optionsmax:
		var option_choice = itemOptions.instantiate()
		option_choice.item = get_random_item()
		upgradeOptions.add_child(option_choice)
		options += 1
	get_tree().paused = true

func upgrade_character(upgrade):
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	upgrade_weapon(upgrade.id)
	levelPanel.visible = false
	levelPanel.position = Vector2(800,50)
	get_tree().paused = false
	calculate_experience(0)
	
func get_random_item():
	var dblist = []
	var collectedIds: Array[String] = []
	
	for c in collected_weapons:
		collectedIds.append(c.data.id)
		if not c.data.id in collectedIdsCompareStringHist:
			collectedIdsCompareStringHist.append(c.data.id)
	
	for i in weapons_db.weapons:
		if i.id in collectedIdsCompareStringHist: #Encontrar upgrades ja coletados
			pass
		elif i in upgrade_options: #Se o upgrade ja for uma opcao
			pass
		elif i.prerequisite_ids.size() > 0: #checando prerequisitos
			for n in i.prerequisite_ids:
				if not n in collectedIdsCompareStringHist:
					pass
				else:
					dblist.append(i)
					collectedIdsCompareStringHist.append(i)
		else:
			dblist.append(i)
			collectedIdsCompareStringHist.append(i)
	if dblist.size() > 0:
		var randomitem = dblist.pick_random()
		upgrade_options.append(randomitem)
		return randomitem
	else:
		return null
