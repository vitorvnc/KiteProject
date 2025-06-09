extends CharacterBody2D

@export var hp = 80.0
@export var movement_speed = 80.0
@export var rotation_speed = 4.5
@export var upper_limit: float = -20 #LIMITE SUPERIOR DA TELA
@export var lower_limit: float = 1300 #LIMITE INFERIOR DA TELA

@onready var walkTimer = get_node("%walkAnimationTimer")
@onready var sprite = $SpritePipa
@onready var collisionPipa = $CollisionPipa

func _physics_process(delta: float) -> void:
	var y_altura = global_position.y
	handle_rotation()
	movement()
	if y_altura < upper_limit or y_altura > lower_limit:
		print("MORREU")
		
	var collision = move_and_collide(velocity * delta)
	if collision:
		debug_collision_details(collision)
	
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

func killPlayer():
	pass

func debug_collision_details(collision: KinematicCollision2D):
	var collider = collision.get_collider()
	print("=== DETECTED COLLISION ===")
	print("Collided object: %s (%s)" % [collider.name if collider else "null", collider.get_class() if collider else "null"])
	print("Collision Position: ", collision.get_position())
	print("Collision Normal: ", collision.get_normal())
	print("Penetration Distance: ", collision.get_depth())
	
	if collider is TileMap:
		var tilemap_pos = collider.local_to_map(collision.get_position())
		print("TileMap Position: ", tilemap_pos)
		 # Verifica todas as camadas do TileMap
		for layer in range(collider.get_layers_count()):
			var tile_data = collider.get_cell_tile_data(layer, tilemap_pos)
			if tile_data:
				print(" - Camada %d: " % layer, 
					  "Física: ", tile_data.get_physics_layer(),
					  " | Material: ", tile_data.get_physics_material())
