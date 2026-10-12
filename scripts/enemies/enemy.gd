extends CharacterBody3D
class_name Enemy

signal died(enemy: Enemy)

## Stats of this enemy type. Injected by the spawner before entering the tree
## (not set in the scene: the EnemyData already references the scene).
var data: EnemyData
## Node the enemy chases. Set by the spawner; null = stand still.
var target: Node3D

## Read by the player's hurtbox.
var contact_damage: int:
	get:
		return data.contact_damage if data else 0

@onready var health: HealthComponent = %HealthComponent
@onready var visual: Node3D = %Visual
@onready var behavior: EnemyBehavior = _find_behavior()

func _ready() -> void:
	add_to_group("enemies")
	health.died.connect(_on_health_died)
	if data == null:
		push_warning("Enemy '%s' without EnemyData, it will not move." % name)
		return
	# The HealthComponent is ready before us and already took its scene max HP.
	health.max_health = data.max_health
	health.set_current_health(data.max_health)

func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	if data and behavior:
		velocity = behavior.physics_step(self, delta)
	var direction := Vector3(velocity.x, 0.0, velocity.z)
	if direction.length_squared() > 0.0001:
		var target_angle := atan2(direction.x, direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, 1.0 - exp(-data.turn_speed * delta))
	move_and_slide()

## `source_position`: where the hit comes from, Vector3.INF when unknown
## (used by enemies that react to the hit direction).
func take_damage(amount: int, _source_position: Vector3 = Vector3.INF) -> bool:
	return health.take_damage(amount)

func _find_behavior() -> EnemyBehavior:
	for child in get_children():
		if child is EnemyBehavior:
			return child
	push_warning("Enemy '%s' without an EnemyBehavior child." % name)
	return null

func _on_health_died() -> void:
	died.emit(self)
	queue_free()
