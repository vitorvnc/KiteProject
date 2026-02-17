# RabiolaManager.gd
extends Node2D

class_name RabiolaManager

@export var target_node: Node2D
@export var segments_count: int = 10
@export var segment_distance: float = 10.0
@export var segment_texture: Texture2D
@export var segment_size: Vector2 = Vector2(16, 16)
@export var smooth_speed: float = 8.0

var segments: Array[Sprite2D] = []
var positions_history: Array[Vector2] = []
var rotations_history: Array[float] = []
var max_history: int = 100

func _ready():
	initialize_segments()

func initialize_segments():
	for i in range(segments_count):
		var sprite = Sprite2D.new()
		sprite.texture = segment_texture
		sprite.scale = segment_size / segment_texture.get_size() if segment_texture else Vector2.ONE
		
		# Gradiente de opacidade
		var alpha = lerp(0.3, 1.0, float(i) / float(segments_count))
		sprite.modulate = Color(1, 1, 1, alpha)
		
		add_child(sprite)
		segments.append(sprite)
		
		# Inicializa histórico
		if target_node:
			positions_history.append(target_node.global_position)
			rotations_history.append(target_node.global_rotation)

func _process(delta):
	if not target_node:
		return
	
	# Atualiza histórico
	positions_history.push_front(target_node.global_position)
	rotations_history.push_front(target_node.global_rotation)
	
	if positions_history.size() > max_history:
		positions_history.pop_back()
		rotations_history.pop_back()
	
	# Atualiza segmentos
	for i in range(segments_count):
		var history_index = min(i * int(segment_distance), positions_history.size() - 1)
		
		if history_index < positions_history.size():
			var target_pos = positions_history[history_index]
			var target_rot = rotations_history[history_index]
			
			# Interpolação suave
			segments[i].global_position = segments[i].global_position.lerp(target_pos, smooth_speed * delta)
			segments[i].global_rotation = lerp_angle(segments[i].global_rotation, target_rot, smooth_speed * delta)
