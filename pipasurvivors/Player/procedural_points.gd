extends Node2D

@onready var body: Line2D = $body
@export var radius: int = 20
@onready var player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	print("DEBUG: Player encontrado? ", player != null)
	if player:
		print("DEBUG: Player global position: ", player.global_position)
		print("DEBUG: Este nó global position: ", global_position)
		
		var player_local_pos = player.global_position - global_position
		print("DEBUG: Player local position calculada: ", player_local_pos)
		
		for i in range(body.points.size()):
			body.points[i] = player_local_pos

func _process(delta: float) -> void:
	if not player:
		return
	
	var pts = body.points
	var player_local_pos = to_local(player.global_position - global_position)
	var player_pos = to_local(player.global_position)
	var player_pos_ng = player.global_position
	self.global_position = player_pos_ng
	$".".global_position = player_pos_ng
	pts[0] = player_pos_ng
	body.set_point_position(0, player_pos_ng)
	
	for i in range(1, pts.size()):
		pts[i] = pts[i-1] + (pts[i] - pts[i-1]).limit_length(radius)
	
	body.points = pts
	queue_redraw()
