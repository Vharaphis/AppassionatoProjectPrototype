extends CharacterBody3D
class_name Enemy

signal died(enemy: Enemy)

@export var move_speed: float = 3.5
@export var contact_damage: int = 10
@export var turn_speed: float = 10.0

## Node the enemy chases. Set by the spawner; null = stand still.
var target: Node3D

@onready var health: HealthComponent = %HealthComponent
@onready var visual: Node3D = %Visual

func _ready() -> void:
	add_to_group("enemies")
	health.died.connect(_on_health_died)

func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	if is_instance_valid(target):
		var to_target := target.global_position - global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.0001:
			var direction := to_target.normalized()
			velocity = direction * move_speed
			var target_angle := atan2(direction.x, direction.z)
			visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, 1.0 - exp(-turn_speed * delta))
	move_and_slide()

func take_damage(amount: int) -> bool:
	return health.take_damage(amount)

func _on_health_died() -> void:
	died.emit(self)
	queue_free()
