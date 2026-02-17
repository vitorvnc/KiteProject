extends Node2D

var anchor :Vector2 = Vector2(200.0, 200.0)
var point :Vector2 = Vector2(200.0, 400.0)

@onready var body: Line2D = $body
@export var radius :int = 10
@onready var player = get_tree().get_first_node_in_group("player")
@onready var target_cauda: Marker2D = player.get_node("TargetCaudaPipa")

#func _ready() -> void:
	#for i in range(body.points.size()):
		#body.points[i] = Vector2(player.global_position.y * 1.2, player.global_position.y * -1)
		#body.points[i] = Vector2(i * 2, 200.0)
		
func _process(delta: float) -> void:
	var pts = body.points
	# O primeiro ponto da linha segue a posição global da pipa
	if target_cauda:
		var testLocal = player.to_local(target_cauda.global_position)
		pts[0] = target_cauda.global_position
	# Os demais pontos seguem o anterior, limitados pelo raio
	for i in range(1, pts.size()):
		pts[i] = pts[i - 1] + (pts[i] - pts[i - 1]).limit_length(radius)
	body.points = pts
	queue_redraw()


#func _draw() -> void:
	#
	#draw_circle(anchor, 10, "white")
	#draw_line(anchor,point,"red", 5)
	#draw_circle(point, 10, "green")
