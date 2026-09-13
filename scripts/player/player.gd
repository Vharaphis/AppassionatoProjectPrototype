extends CharacterBody3D
class_name Player

signal died

@export var move_speed: float = 6.0
@export var acceleration: float = 60.0
@export var turn_speed: float = 14.0

var is_alive: bool = true

@onready var health: HealthComponent = %HealthComponent
@onready var hurtbox: Area3D = %Hurtbox
@onready var visual: Node3D = %Visual

func _ready() -> void:
	add_to_group("player")
	health.died.connect(_on_health_died)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	_move(delta)
	_check_enemy_contacts()

func _process(_delta: float) -> void:
	# Blink while invulnerable so the player notices the hit.
	if is_alive and health.is_invulnerable():
		visual.visible = Time.get_ticks_msec() % 120 < 60
	else:
		visual.visible = true

func _move(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input.x, 0.0, input.y)
	var target_velocity := direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	velocity.y = 0.0
	move_and_slide()

	if direction.length_squared() > 0.01:
		var target_angle := atan2(direction.x, direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, 1.0 - exp(-turn_speed * delta))

func _check_enemy_contacts() -> void:
	if health.is_invulnerable():
		return
	var damage := 0
	for body in hurtbox.get_overlapping_bodies():
		if body is Enemy:
			damage = maxi(damage, (body as Enemy).contact_damage)
	if damage > 0:
		health.take_damage(damage)

func _on_health_died() -> void:
	is_alive = false
	velocity = Vector3.ZERO
	hurtbox.set_deferred("monitoring", false)
	# Placeholder death pose: lay the capsule on the floor.
	visual.position.y = 0.5
	visual.rotation.x = -PI / 2.0
	died.emit()
