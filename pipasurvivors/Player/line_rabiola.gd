extends Line2D

@export var radius :int = 20
@onready var player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	for i in points:
		i = Vector2(get_parent().global_position)

func _physics_process(delta: float) -> void:
	var parent = get_parent()
	var player_pos = get_parent().position
	var pts = points
	pts[0] = player_pos
	for i in range(1, pts.size()):
		pts[i] = pts[i-1] + (pts[i] - pts[i-1]).limit_length(radius)
		
	points = pts
	
	queue_redraw()
