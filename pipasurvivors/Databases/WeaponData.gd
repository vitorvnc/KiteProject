extends Resource
class_name WeaponData

enum AttackType {SINGLE, CONTINUOUS}
@export var id: String = ""
@export var icon: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var attack_type: AttackType = AttackType.SINGLE
@export var level: int = 1
@export var prerequisite_ids: Array[String] = []
@export var type: String = "weapon"  # "weapon" ou "upgrade"
@export var attack_scene: PackedScene  # Cena do ataque associada
@export var base_damage: float = 10.0
@export var knockback_force: float = 100.0
@export var cooldown: float = 1.0
@export var speed: float = 350.0
@export var projectile_count: int = 1
@export var projectile_cooldown: float = 0.2
@export var attack_range: float = 100.0
@export var pierce_count: int = 1
@export var attack_size: float = 1.0
@export var spawn_point_path: NodePath  # Caminho para o Marker2D no player
@export var is_child_attack: bool = false  # Se true, será child do player
@export var knockback_direction: Vector2 = Vector2.UP
@export var upgrade_ammount: float
