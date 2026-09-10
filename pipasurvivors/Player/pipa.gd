extends CharacterBody2D
#region PROPRIEDADES


@export var hp = 80.0
@export var maxhp = 80.0
@export var movement_speed = 50.0
@export var rotation_speed = 4.5
@export var upper_limit: float = -20 #LIMITE SUPERIOR DA TELA
@export var lower_limit: float = 1300 #LIMITE INFERIOR DA TELA
@onready var walkTimer = get_node("%walkAnimationTimer")
@onready var sprite = $SpritePipa
@onready var collisionPipa = $CollisionPipa

var time = 0
var experience = 0
var experience_level = 1
var collected_experience = 0

#ATTACK E WEAPONS
@export var attack_spawn_point: Marker2D  # Ponto de spawn dos ataques Whip
@export var weapons_db: WeaponDatabase
@export var starting_weapons: Array[Dictionary] = [  # IDs e levels das armas iniciais
	{'id': 'waveatk_1', 'level': 1}
]
var active_attacks: Array[Node] = []
var collected_weapons: Array[Dictionary] = []  # {data: WeaponData, level: x, timer: Timer}

var collectedIdsCompareStringHist: Array[String] = []

# DASH SYSTEM
@onready var snd_dash = get_node("%snd_dash")
@export_group("Dash System")
@export var dash_enabled: bool = true
@export var dash_speed_multiplier: float = 3.0  # Multiplicador de velocidade durante o dash
@export var dash_duration: float = 0.3  # Duração do dash em segundos
@export var dash_cooldown: float = 1.0  # Cooldown entre dashes
@export var dash_particles_enabled: bool = true  # Se quer usar partículas

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var original_movement_speed: float
var dash_particles: GPUParticles2D  # Opcional: para efeito visual

#GUI
@onready var expBar = get_node("%ExperienceBar")
@onready var lblLevel = get_node("%lbl_level")
@onready var levelPanel = get_node("%LevelUp")
@onready var upgradeOptions = get_node("%UpgradeOptions")
@onready var itemOptions = preload("res://Utility/item_option.tscn")
@onready var sndLevelUp = get_node("%snd_levelup")
@onready var healthBar = get_node("%HealthBar")
@onready var lblTimer = get_node("%lblTimer")

@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")
@onready var sndVictory = get_node ("%snd_victory")
@onready var sndLose = get_node ("%snd_lose")

#tabela grid com upgrades e weapons
@onready var collectedWeapons = get_node("%CollectedWeapons")
@onready var collectedUpgrades = get_node("%CollectedUpgrades")
@onready var itemContainer = preload("res://Player/GUI/item_container.tscn")

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

#Signal
signal playerdeath
#endregion

#region FUNCTIONS
func _ready():
	set_expbar(experience, calculate_experiencecap())
	_on_hurt_box_hurt(0,0,0)
	attack_spawn_point = $AttackSpawnPoint
	var weapon = load("res://Utility/weapons_db.tres::Resource_mqtek")
	load_starting_weapons()
	
		# Salva a velocidade original
	original_movement_speed = movement_speed
	
	# Opcional: Cria partículas para o dash
	if dash_particles_enabled:
		setup_dash_particles()
	
#region MOVIMENTO
func _physics_process(delta: float) -> void:
	# Processa timers do dash
	if is_dashing:
		process_dash(delta)

	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	var y_altura = global_position.y
	handle_rotation()
	movement()

	# Input do dash (apenas uma vez quando pressiona espaço)
	if Input.is_action_just_pressed("spacebar") and dash_enabled and not is_dashing and dash_cooldown_timer <= 0:
		activate_dash()
	
	var collision = move_and_collide(velocity * delta)
	update_attack_directions()
	
	# Atualiza o inimigo alvo periodicamente
	if Engine.get_frames_drawn() % 30 == 0:
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
	
#DASH
func setup_dash_particles():
	# Cria um sistema de partículas para o efeito de dash
	dash_particles = GPUParticles2D.new()
	dash_particles.amount = 6
	dash_particles.lifetime = 0.4
	dash_particles.speed_scale = 0.6
	dash_particles.one_shot = true
	dash_particles.emitting = false
	
	# Configura o material das partículas
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, 1, 0)  # Direção para baixo
	particle_material.spread = 45.0  # AUMENTADO: Mais espalhamento horizontal
	particle_material.gravity = Vector3(0, 0, 0)
	particle_material.initial_velocity_min = 40.0
	particle_material.initial_velocity_max = 80.0
	particle_material.angular_velocity_min = 0.0
	particle_material.angular_velocity_max = 0.0
	particle_material.scale_min = 0.5
	particle_material.scale_max = 1.0
	dash_particles.process_material = particle_material
	
	# Configura a textura com traços em posições alternadas (zig-zag)
	var wind_texture = create_zigzag_streaks_texture()
	dash_particles.texture = wind_texture
	
	# Posiciona as partículas atrás da pipa
	dash_particles.position = Vector2(0, 15)
	
	add_child(dash_particles)

func create_zigzag_streaks_texture() -> Texture2D:
	# Cria uma textura com múltiplos traços em padrão zig-zag
	var width = 35   # Largura maior para espalhar os traços
	var height = 60  # Altura para os traços verticais
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Número de traços na textura (serão 6 traços em zig-zag)
	var num_streaks = 4
	var streak_height = 26  # Altura de cada traço
	var streak_width = 2.5    # Largura de cada traço
	
	# Cor base verde
	var base_hue = 0.25
	var base_saturation = 0.8
	var base_value = 0.8
	
	for i in range(num_streaks):
		# Posição X alternada (zig-zag)
		var t = float(i) / float(num_streaks - 1) if num_streaks > 1 else 0
		
		# Zig-zag: vai da esquerda pra direita e volta
		var zigzag_offset = sin(t * PI * 2) * 0.5 + 0.5  # 0 a 1
		var x_position = 5 + zigzag_offset * (width - 10)  # Espaço das bordas
		
		# Posição Y com leve variação
		var y_position = 5 + t * (height - streak_height - 10)
		
		# MUDANÇA: Opacidade reduzida para 50%
		var color = Color.from_hsv(
			base_hue + (i % 2) * 0.05,
			base_saturation + randf() * 0.2,
			base_value + randf() * 0.2,
			0.5  # MUDANÇA: Opacidade fixa em 50% (era 0.9)
		)
		
		# Ângulo levemente inclinado (alterna direção)
		var angle = (i - (num_streaks - 1) / 2.0) * 0.08
		if i % 2 == 0:
			angle = -angle  # Inverte ângulo para efeito zig-zag
		
		# Desenha o traço
		draw_single_streak(image, x_position, y_position, streak_width, streak_height, angle, color)
	
	# Suaviza a textura
	image.blit_rect(image, Rect2(0, 0, width, height), Vector2(0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func draw_single_streak(image: Image, x_center: float, y_center: float, width: int, height: int, angle: float, color: Color):
	# Desenha um único traço com a posição, tamanho e ângulo especificados
	for y in range(height):
		# Espessura variável ao longo do traço (mais grosso no meio)
		var t = float(y) / float(height - 1) if height > 1 else 0
		var thickness = sin(t * PI) * width * 0.8
		
		# Posição X com ângulo
		var x_offset = tan(angle) * (y - height/2)
		var center_x = x_center + x_offset
		
		for x in range(-int(thickness), int(thickness) + 1):
			var pixel_x = int(center_x + x)
			var pixel_y = int(y_center + y)
			
			if pixel_x >= 0 and pixel_x < image.get_width() and pixel_y >= 0 and pixel_y < image.get_height():
				# Gradiente de opacidade (agora com base na opacidade de 50%)
				var dist_factor = 1.0 - abs(float(x) / max(thickness, 1.0))
				var alpha = (0.3 + 0.7 * pow(dist_factor, 1.5)) * color.a  # MUDANÇA: Multiplica pela opacidade da cor
				
				var final_color = color
				final_color.a = alpha  # MUDANÇA: Define alpha diretamente
				
				image.set_pixel(pixel_x, pixel_y, final_color)

func activate_dash():
	is_dashing = true
	dash_timer = dash_duration
	
	# Aplica o multiplicador de velocidade
	movement_speed = original_movement_speed * dash_speed_multiplier
	
	# Efeito visual: partículas
	if dash_particles_enabled and dash_particles:
		dash_particles.emitting = true
		dash_particles.restart()
	
	# Opcional: Efeito de escala/sprite
	create_dash_visual_effect()
	
	# Opcional: Som de dash
	play_dash_sound()
	
	print("Dash ativado! Velocidade: ", movement_speed)

func process_dash(delta: float):
	dash_timer -= delta
	
	if dash_timer <= 0:
		end_dash()

func end_dash():
	is_dashing = false
	movement_speed = original_movement_speed
	dash_cooldown_timer = dash_cooldown
	
	# Efeito visual de fim de dash
	if dash_particles_enabled and dash_particles:
		dash_particles.emitting = false
	
	print("Dash terminado. Cooldown: ", dash_cooldown_timer)

func create_dash_visual_effect():
	# Efeito rápido de escala no sprite da pipa
	if sprite:
		var original_scale = sprite.scale
		var tween = create_tween()
		tween.tween_property(sprite, "scale", original_scale * 1.1, 0.1)
		tween.tween_property(sprite, "scale", original_scale, 0.2)
		
		# Efeito de rotação rápida
		var original_rotation_offset = sprite.rotation
		tween.parallel().tween_property(sprite, "rotation", original_rotation_offset + 0.2, 0.1)
		tween.parallel().tween_property(sprite, "rotation", original_rotation_offset, 0.2)

func play_dash_sound():
	# Se você tiver um nó de áudio para efeitos
	if has_node("%snd_dash"):
		var dash_sound = get_node("%snd_dash") as AudioStreamPlayer
		if dash_sound:
			dash_sound.play()
#endregion

func killPlayer():
	pass
	
func _on_hurt_box_hurt(damage: Variant, _angle, _knockback) -> void:
	hp-= damage-armor
	healthBar.max_value = maxhp
	healthBar.value = hp
	if hp <= 0:
		death()
	
#region #ATAQUES E ARMAS
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
			var new_item = itemContainer.instantiate()
			new_item.upgrade = weapon_data
			match weapon_data.type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)

func add_weapon(weapon_data: WeaponData):
	print('entrou no add weapon', weapon_data)
	if not weapon_data or (not weapon_data.attack_scene && not weapon_data.type=="upgrade"):
		hp += weapon_data.upgrade_ammount
		hp = clamp(hp,0,maxhp)
		return
	
	if weapon_data.type=="weapon":
		#TIMER DO ATAQUE(triga o ataque com base no cd entre os projeteis)
		var projectile_timer = Timer.new()
		projectile_timer.name = "SequenceTimer_" + weapon_data.id
		projectile_timer.wait_time = weapon_data.projectile_cooldown
		projectile_timer.one_shot = true
		projectile_timer.autostart = false
		projectile_timer.timeout.connect(
			func():
			var weapon_indexFinder = _find_weapon_index(weapon_data.id)
			if weapon_indexFinder != -1:
				collected_weapons[weapon_indexFinder]["flipAttack"] = !collected_weapons[weapon_indexFinder]["flipAttack"]
				_spawn_weapon_attack(weapon_data.id)
			CONNECT_PERSIST
		)
		#TIMER PRINCIPAL(Timer geral do cooldown do ataque)
		var main_timer = Timer.new()
		main_timer.name = "Timer_" + weapon_data.id
		main_timer.wait_time = weapon_data.cooldown
		main_timer.one_shot = false
		main_timer.autostart = false
		
		main_timer.timeout.connect(
			func():
				var weapon_index = _find_weapon_index(weapon_data.id)
				if weapon_index != -1:
					collected_weapons[weapon_index]["current_ammo"] = weapon_data.projectile_count
				_spawn_weapon_attack(weapon_data.id),
				CONNECT_PERSIST
			)
		
		# Adiciona à árvore e inicia
		add_child(main_timer)
		main_timer.add_child(projectile_timer)
		
		collected_weapons.append({
			"data": weapon_data,
			"timer": main_timer,
			"projectile_timer": projectile_timer,
			"current_ammo": weapon_data.projectile_count,
			"flipAttack": true,
		})
		
		main_timer.start()
	else:
		match weapon_data.id.split("_")[0]:
			"reel":
				movement_speed += weapon_data.upgrade_ammount
			"armor":
				armor += weapon_data.upgrade_ammount
		collected_weapons.append({
			"data": weapon_data,
			"timer": null,
			"projectile_timer": null,
			"current_ammo": null,
			"flipAttack": true,
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
		if collected_weapons[weapon_index]["data"].type == "weapon":
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
	
	var weapon_index = _find_weapon_index(weapon_id)
	if weapon_index == -1:
		return
	var weapon_entry = collected_weapons[weapon_index]
		
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
				weapon_data,
				weapon_entry["flipAttack"]
			)
	else:
		get_parent().add_child(attack_instance)  # Anexa à cena
		var target_pos = target_enemy.global_position if target_enemy else Vector2.RIGHT.rotated(rotation)
		if attack_instance.has_method("setup"):
			attack_instance.setup(attack_spawn_point.global_position, target_pos, weapon_data)
	
	# Reduz a munição
	weapon_entry["current_ammo"] -= 1
	
	# Se ainda tem munição, inicia o timer para o próximo projétil
	if weapon_entry["current_ammo"] > 0:
		weapon_entry["projectile_timer"].start()

func _find_weapon_index(weapon_id: String) -> int:
	for i in range(collected_weapons.size()):
		if collected_weapons[i]["data"].id.begins_with(weapon_id.split("_")[0]):
			return i
	return -1

#endregion

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
	tween.tween_property(levelPanel, "position", Vector2(100,200), 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelPanel.visible = true
	var options = 0
	var optionsmax = 3
	while options < optionsmax:
		var option_choice = itemOptions.instantiate()
		option_choice.item = get_random_item()
		option_choice.position.x = option_choice.position.x + 50
		upgradeOptions.add_child(option_choice)
		options += 1
	get_tree().paused = true

func upgrade_character(upgrade):
	adjust_gui_collection(upgrade)
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
	var countPreReqs = 0
	
	for c in collected_weapons:
		collectedIds.append(c.data.id)
		if not c.data.id in collectedIdsCompareStringHist:
			collectedIdsCompareStringHist.append(c.data.id)
	
	for i in weapons_db.weapons:
		if i.type == "recovery":
			pass
		elif i.id in collectedIdsCompareStringHist: #Encontrar upgrades ja coletados
			pass
		elif i in upgrade_options: #Se o upgrade ja for uma opcao
			pass
		elif i.prerequisite_ids.size() > 0: #checando prerequisitos
			countPreReqs = 0
			for n in i.prerequisite_ids:
				if not n in collectedIdsCompareStringHist:
					pass
				else:
					countPreReqs +=1
			if(countPreReqs == i.prerequisite_ids.size()):
				dblist.append(i)
		else:
			dblist.append(i)
	if dblist.size() > 0:
		var randomitem = dblist.pick_random()
		upgrade_options.append(randomitem)
		return randomitem
	else:
		return null

func change_time(argtime = 0):
	time = argtime
	var get_m = int(time/60.0)
	var get_s = time % 60
	if get_m < 10:
		get_m = str(0,get_m)
	if get_s <10:
		get_s = str(0, get_s)
	lblTimer.text = str(get_m, ":", get_s)

func adjust_gui_collection(upgrade):
	var get_upgraded_displaynames = upgrade.display_name
	var get_type = upgrade.type
	if get_type != "recovery":
		var get_collected_displaynames = []
		for i in collected_weapons:
				get_collected_displaynames.append(i.data.display_name)
		if not get_upgraded_displaynames in get_collected_displaynames:
			var new_item = itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)

func death():
	deathPanel.visible = true
	emit_signal("playerdeath")
	get_tree().paused = true
	var tween = deathPanel.create_tween()
	tween.tween_property(deathPanel, "position", Vector2(100,120), 3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	if time >= 300:
		lblResult.text = "You Win"
		sndVictory.play()
	else:
		lblResult.text = "You Lose"
		sndLose.play()

func _on_btn_menu_click_end() -> void:
	get_tree().paused = false
	var _level = get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")
#endregion
