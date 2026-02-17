extends Node2D

class_name WavyCircle

@export var base_radius: float = 150.0
@export var color: Color = Color.CYAN
@export var line_width: float = 10.0
@export var segments: int = 360
@export var geometry_wave_amplitude: float = 5.0
@export var geometry_wave_frequency: float = 15.0
@export var geometry_wave_speed: float = 3.0
@export var use_shader_effects: bool = true

# Novos parâmetros para preenchimento e círculos concêntricos
@export var fill_enabled: bool = true
@export_range(0.0, 1.0) var fill_opacity: float = 0.2  # 20% de opacidade
@export var target_effect_enabled: bool = true
@export_range(1, 10) var concentric_circles: int = 5
@export var circle_spacing: float = 0.8  # Espaço entre círculos (0.0 a 1.0)
@export_range(0.0, 1.0) var inner_circles_opacity: float = 0.6  # Opacidade dos círculos internos

# Parâmetros do shader - agora vinculados ao material
@export_range(0.0, 5.0) var shader_pulse_speed: float = 3.0:
	set(value):
		shader_pulse_speed = value
		if shader_material:
			shader_material.set_shader_parameter("pulse_speed", value)

@export_range(0.0, 1.0) var shader_glow_intensity: float = 1.0:
	set(value):
		shader_glow_intensity = value
		if shader_material:
			shader_material.set_shader_parameter("glow_intensity", value)

@export_range(0.0, 2.0) var shader_color_cycle_speed: float = 2.0:
	set(value):
		shader_color_cycle_speed = value
		if shader_material:
			shader_material.set_shader_parameter("color_cycle_speed", value)

# Caminho para o arquivo de shader
@export var shader_path: String = "res://wavy_circle_shader.gdshader"

var time: float = 0.0
var line_node: Line2D
var shader_material: ShaderMaterial
var fill_polygon_node: Polygon2D
var inner_circles: Array[Line2D] = []

func _ready():
	# Cria o nó Line2D para o contorno
	create_line_node()
	
	# Cria o nó para preenchimento
	if fill_enabled:
		create_fill_polygon()
	
	# Cria os círculos internos para efeito de alvo
	if target_effect_enabled:
		create_inner_circles()
	
	# Cria/Configura o material de shader
	if use_shader_effects:
		setup_shader_material()
		apply_shader_to_all_nodes()
	
	# Inicia a animação
	set_process(true)

func create_line_node():
	line_node = Line2D.new()
	line_node.width = line_width
	line_node.default_color = color
	
	# Configurações de qualidade da linha
	line_node.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	line_node.joint_mode = Line2D.LINE_JOINT_ROUND
	line_node.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line_node.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	add_child(line_node)

func create_fill_polygon():
	fill_polygon_node = Polygon2D.new()
	fill_polygon_node.color = color
	fill_polygon_node.color.a = fill_opacity  # 20% de opacidade
	add_child(fill_polygon_node)
	
	# Coloca o preenchimento atrás da linha
	move_child(fill_polygon_node, 0)

func create_inner_circles():
	# Limpa círculos existentes
	for circle in inner_circles:
		if is_instance_valid(circle):
			circle.queue_free()
	inner_circles.clear()
	
	# Cria círculos concêntricos
	if concentric_circles < 2:
		return
	
	var spacing = base_radius * (circle_spacing / concentric_circles)
	
	for i in range(1, concentric_circles):
		var circle = Line2D.new()
		circle.width = line_width * 0.5  # Linha mais fina para círculos internos
		
		# Usa a mesma cor base, mas com opacidade ajustada
		var inner_color = color
		inner_color.a = inner_circles_opacity
		circle.default_color = inner_color
		
		# Configurações de qualidade
		circle.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		circle.joint_mode = Line2D.LINE_JOINT_ROUND
		circle.begin_cap_mode = Line2D.LINE_CAP_ROUND
		circle.end_cap_mode = Line2D.LINE_CAP_ROUND
		
		# Calcula raio para este círculo
		var inner_radius = (base_radius * i) / concentric_circles
		
		# Gera pontos para círculo interno (sem ondulação inicial)
		var points: PackedVector2Array = []
		for j in range(segments + 1):
			var angle = TAU * j / segments
			var point = Vector2(cos(angle), sin(angle)) * inner_radius
			points.append(point)
		
		circle.points = points
		add_child(circle)
		inner_circles.append(circle)
		
		# Move para ficar atrás da linha principal
		move_child(circle, 0)

func setup_shader_material():
	if not ResourceLoader.exists(shader_path):
		push_warning("Shader não encontrado em: ", shader_path)
		create_fallback_shader_material()
		return
	
	shader_material = ShaderMaterial.new()
	var shader = load(shader_path) as Shader
	
	if shader:
		shader_material.shader = shader
		
		# Configura parâmetros iniciais
		shader_material.set_shader_parameter("time", time)
		shader_material.set_shader_parameter("pulse_speed", shader_pulse_speed)
		shader_material.set_shader_parameter("glow_intensity", shader_glow_intensity)
		shader_material.set_shader_parameter("color_cycle_speed", shader_color_cycle_speed)
		shader_material.set_shader_parameter("base_color", color)
	else:
		push_warning("Falha ao carregar shader. Criando material simples.")
		create_fallback_shader_material()

func create_fallback_shader_material():
	shader_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	render_mode unshaded;
	
	uniform float time = 0.0;
	uniform float pulse_speed = 2.0;
	
	void fragment() {
		float pulse = sin(time * pulse_speed) * 0.2 + 0.8;
		COLOR = texture(TEXTURE, UV) * vec4(pulse, pulse, pulse, 1.0);
	}
	"""
	shader_material.shader = shader

func apply_shader_to_all_nodes():
	if not use_shader_effects or not shader_material:
		return
	
	# Aplica shader apenas à linha principal (contorno)
	line_node.material = shader_material
	
	# Para os círculos internos, podemos usar o mesmo shader ou um mais simples
	for circle in inner_circles:
		circle.material = shader_material
	
	# Para o preenchimento, sem shader (mantém opacidade fixa)
	if fill_polygon_node:
		fill_polygon_node.material = null

func _process(delta):
	time += delta * geometry_wave_speed
	
	# Atualiza a geometria do círculo principal
	update_circle_geometry()
	
	# Atualiza o preenchimento
	if fill_enabled and fill_polygon_node:
		update_fill_polygon()
	
	# Atualiza círculos internos
	if target_effect_enabled and not inner_circles.is_empty():
		update_inner_circles()
	
	# Atualiza parâmetros do shader
	if use_shader_effects and shader_material:
		shader_material.set_shader_parameter("time", time)
		shader_material.set_shader_parameter("base_color", color)

func update_circle_geometry():
	var points: PackedVector2Array = []
	
	# Gera pontos com ondulação
	for i in range(segments + 1):
		var angle = TAU * i / segments
		
		# Ondulação na geometria
		var wave = sin(angle * geometry_wave_frequency + time) * geometry_wave_amplitude
		var current_radius = base_radius + wave
		
		var point = Vector2(cos(angle), sin(angle)) * current_radius
		points.append(point)
	
	# Aplica os pontos ao Line2D
	line_node.points = points
	
	# Emite sinal com os pontos atualizados
	emit_signal("geometry_updated", points)

func update_fill_polygon():
	if not fill_polygon_node or line_node.points.size() < 3:
		return
	
	# Usa os pontos da linha (sem o último ponto que fecha o polígono)
	var fill_points = line_node.points.slice(0, line_node.points.size() - 2)
	fill_polygon_node.polygon = fill_points
	
	# Atualiza cor com opacidade
	fill_polygon_node.color = color
	fill_polygon_node.color.a = fill_opacity

func update_inner_circles():
	for circle_idx in inner_circles.size():
		var circle = inner_circles[circle_idx]
		var radius_ratio = float(circle_idx + 1) / (inner_circles.size() + 1)
		var inner_radius = base_radius * radius_ratio
		
		var points: PackedVector2Array = []
		for i in range(segments + 1):
			var angle = TAU * i / segments
			
			# Ondulação mais suave para círculos internos
			var wave = sin(angle * geometry_wave_frequency * 0.5 + time * 0.8) * geometry_wave_amplitude * 0.3
			var current_radius = inner_radius + wave
			
			var point = Vector2(cos(angle), sin(angle)) * current_radius
			points.append(point)
		
		circle.points = points
		
		# Atualiza cor dos círculos internos (herda a cor base)
		var inner_color = color
		inner_color.a = inner_circles_opacity
		circle.default_color = inner_color

# Métodos para atualizar cores de todos os elementos
func update_all_colors():
	# Atualiza linha principal
	line_node.default_color = color
	
	# Atualiza preenchimento
	if fill_polygon_node:
		fill_polygon_node.color = color
		fill_polygon_node.color.a = fill_opacity
	
	# Atualiza círculos internos
	for circle in inner_circles:
		var inner_color = color
		inner_color.a = inner_circles_opacity
		circle.default_color = inner_color
	
	# Atualiza shader
	if shader_material:
		shader_material.set_shader_parameter("base_color", color)

# Setters para garantir que cores são atualizadas
func set_color(new_color: Color):
	color = new_color
	update_all_colors()

func set_fill_opacity(opacity: float):
	fill_opacity = clamp(opacity, 0.0, 1.0)
	if fill_polygon_node:
		fill_polygon_node.color.a = fill_opacity

func set_inner_circles_opacity(opacity: float):
	inner_circles_opacity = clamp(opacity, 0.0, 1.0)
	for circle in inner_circles:
		var inner_color = color
		inner_color.a = inner_circles_opacity
		circle.default_color = inner_color

# Métodos para controlar os novos efeitos
func set_fill_enabled(enabled: bool):
	fill_enabled = enabled
	if fill_polygon_node:
		fill_polygon_node.visible = enabled

func set_target_effect_enabled(enabled: bool):
	target_effect_enabled = enabled
	if enabled:
		if inner_circles.is_empty():
			create_inner_circles()
	else:
		# Esconde círculos internos
		for circle in inner_circles:
			circle.visible = false

func set_concentric_circles(count: int):
	concentric_circles = clamp(count, 1, 10)
	if target_effect_enabled:
		create_inner_circles()
		apply_shader_to_all_nodes()

func set_circle_spacing(spacing: float):
	circle_spacing = clamp(spacing, 0.1, 1.0)
	if target_effect_enabled and not inner_circles.is_empty():
		create_inner_circles()
		apply_shader_to_all_nodes()

# Métodos públicos herdados
func set_wave_amplitude(amplitude: float):
	geometry_wave_amplitude = amplitude

func set_wave_frequency(frequency: float):
	geometry_wave_frequency = frequency

func set_wave_speed(speed: float):
	geometry_wave_speed = speed

func toggle_shader_effects(enabled: bool):
	use_shader_effects = enabled
	if enabled:
		if not shader_material:
			setup_shader_material()
		apply_shader_to_all_nodes()
	else:
		line_node.material = null
		for circle in inner_circles:
			circle.material = null

func reload_shader():
	if use_shader_effects:
		setup_shader_material()
		apply_shader_to_all_nodes()

# Sinal para quando a geometria é atualizada
signal geometry_updated(points: PackedVector2Array)

func _exit_tree():
	if line_node and is_instance_valid(line_node):
		line_node.queue_free()
	if fill_polygon_node and is_instance_valid(fill_polygon_node):
		fill_polygon_node.queue_free()
	for circle in inner_circles:
		if is_instance_valid(circle):
			circle.queue_free()
