extends CharacterBody3D
class_name Enemy

signal died(enemy: Enemy)

## Stats of this enemy type. Injected by the spawner before entering the tree
## (not set in the scene: the EnemyData already references the scene).
var data: EnemyData
## Spawner that created this enemy, used by summoners to add more. May be null.
var spawner: EnemySpawner
## Node the enemy chases. Set by the spawner; null = stand still.
var target: Node3D

## Read by the player's hurtbox. The behaviour may raise it (e.g. while dashing).
var contact_damage: int:
	get:
		if data == null:
			return 0
		return behavior.get_contact_damage(self) if behavior else data.contact_damage

@onready var health: HealthComponent = %HealthComponent
@onready var visual: Node3D = %Visual
@onready var behavior: EnemyBehavior = _find_behavior()

var _tint_material: StandardMaterial3D

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
	var facing := Vector3.ZERO
	if data and behavior:
		velocity = behavior.physics_step(self, delta)
		facing = behavior.get_facing(self)
	if facing == Vector3.ZERO:
		facing = velocity
	facing.y = 0.0
	if data and facing.length_squared() > 0.0001:
		var target_angle := atan2(facing.x, facing.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, 1.0 - exp(-data.turn_speed * delta))
	move_and_slide()

## Direction the enemy's visual faces, on the ground plane.
func get_forward() -> Vector3:
	var forward := visual.global_transform.basis.z
	forward.y = 0.0
	return forward.normalized()

## Flat direction to the target, Vector3.ZERO without one.
func direction_to_target() -> Vector3:
	if not is_instance_valid(target):
		return Vector3.ZERO
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	return to_target.normalized() if to_target.length_squared() > 0.0001 else Vector3.ZERO

func distance_to_target() -> float:
	if not is_instance_valid(target):
		return INF
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	return to_target.length()

## Emissive overlay used to telegraph attacks. A transparent colour clears it.
func set_tint(color: Color) -> void:
	if _tint_material == null:
		_tint_material = StandardMaterial3D.new()
		_tint_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_tint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tint_material.albedo_color = color
	for mesh in visual.find_children("*", "GeometryInstance3D", true, false):
		(mesh as GeometryInstance3D).material_overlay = _tint_material if color.a > 0.0 else null

func clear_tint() -> void:
	set_tint(Color.TRANSPARENT)

## `source_position`: where the hit comes from, Vector3.INF when unknown
## (used by enemies that react to the hit direction).
func take_damage(amount: int, source_position: Vector3 = Vector3.INF) -> bool:
	if behavior and data:
		amount = behavior.modify_damage(self, amount, source_position)
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
