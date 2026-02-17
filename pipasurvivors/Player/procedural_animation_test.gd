extends Node2D

var anchor :Vector2 = Vector2(200.0, 200.0)
var point :Vector2 = Vector2(200.0, 400.0)

@onready var body: Line2D = $body
@export var radius :int = 20
@onready var player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	for i in range(0, body.points.size()):
		body.points[i] = Vector2(i*2, 200.0)
		
func _process(delta: float) -> void:
	var pts = body.points
	var move = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	if move != Vector2.ZERO:
		pts[0] += move * 200 * delta
		
	for i in range(1, pts.size()):
		pts[i] = pts[i-1] + (pts[i] - pts[i-1]).limit_length(radius)
	body.points = pts
	
	queue_redraw()


#func _draw() -> void:
	#
	#draw_circle(anchor, 10, "white")
	#draw_line(anchor,point,"red", 5)
	#draw_circle(point, 10, "green")
