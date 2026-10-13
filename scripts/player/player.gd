extends CharacterBody3D
class_name Player

signal died
signal dash_finished

@export var move_speed: float = 6.0
@export var acceleration: float = 60.0
@export var turn_speed: float = 14.0

var is_alive: bool = true
## Where the player looks (towards the mouse) on the ground plane, aims the cone attacks.
var facing: Vector3 = Vector3.FORWARD

var _dash_velocity: Vector3
var _dash_left: float = 0.0
var _ampli_material: StandardMaterial3D

@onready var health: HealthComponent = %HealthComponent
@onready var hurtbox: Area3D = %Hurtbox
@onready var visual: Node3D = %Visual

func _ready() -> void:
	add_to_group("player")
	health.died.connect(_on_health_died)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	if _dash_left > 0.0:
		_dash_step(delta)
		return
	_move(delta)
	_check_enemy_contacts()

## Rushes `distance` metres along `direction` in `duration` seconds, invulnerable,
## stopped by the walls. Emits `dash_finished` at the end.
func dash(direction: Vector3, distance: float, duration: float) -> void:
	direction.y = 0.0
	if not is_alive or direction.length_squared() < 0.0001 or duration <= 0.0:
		dash_finished.emit()
		return
	_dash_velocity = direction.normalized() * distance / duration
	_dash_left = duration
	health.grant_invulnerability(duration)

## Glow while an Ampli waits for the next card.
func set_amplified(value: bool) -> void:
	if _ampli_material == null:
		_ampli_material = StandardMaterial3D.new()
		_ampli_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ampli_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ampli_material.albedo_color = Color(1.0, 0.8, 0.2, 0.45)
	for mesh in visual.find_children("*", "GeometryInstance3D", true, false):
		(mesh as GeometryInstance3D).material_overlay = _ampli_material if value else null

func is_dashing() -> bool:
	return _dash_left > 0.0

func _dash_step(delta: float) -> void:
	velocity = _dash_velocity
	move_and_slide()
	_dash_left -= delta
	if _dash_left <= 0.0:
		velocity = Vector3.ZERO
		dash_finished.emit()

## Point under the mouse on the player's ground plane, null without a camera
## (headless tests) or when the ray never meets the ground.
func get_mouse_ground_point() -> Variant:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	var mouse := get_viewport().get_mouse_position()
	return Plane(Vector3.UP, global_position.y).intersects_ray(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))

## Flat direction from the player to the mouse, `facing` when unknown.
func get_mouse_direction() -> Vector3:
	var point = get_mouse_ground_point()
	if point == null:
		return facing
	var to_mouse: Vector3 = point - global_position
	to_mouse.y = 0.0
	return to_mouse.normalized() if to_mouse.length_squared() > 0.01 else facing

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

	# The player looks at the mouse; without one (headless tests), along the movement.
	if get_mouse_ground_point() != null:
		facing = get_mouse_direction()
	elif direction.length_squared() > 0.01:
		facing = direction.normalized()
	var target_angle := atan2(facing.x, facing.z)
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
