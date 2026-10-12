class_name PlayerProjectile
extends Node3D

## Homing shot fired by a card. No physics body: it flies to its target and hits
## on arrival, so it never misses and ignores walls.

const HIT_DISTANCE := 0.6
const LIFETIME := 3.0

var target: Enemy
var damage: int = 1
var speed: float = 14.0
var bounces: int = 0
var bounce_range: float = 8.0

var _life := LIFETIME
var _hit: Array[Enemy] = []

func _ready() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.15
	mesh.height = 0.3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.85, 0.3)
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	add_child(visual)

func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0 or not _is_alive(target):
		queue_free()
		return
	var aim := target.global_position + Vector3.UP
	var to_target := aim - global_position
	if to_target.length() <= HIT_DISTANCE:
		_on_hit()
		return
	global_position += to_target.normalized() * minf(speed * delta, to_target.length())

func _on_hit() -> void:
	_hit.append(target)
	target.take_damage(damage, global_position)
	if bounces <= 0:
		queue_free()
		return
	bounces -= 1
	target = _next_target()
	if target == null:
		queue_free()

## Closest live enemy in range not hit yet by this projectile; falls back to the
## ones already hit when none is left.
func _next_target() -> Enemy:
	var best: Enemy
	var best_fresh := false
	var best_distance := bounce_range
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if not _is_alive(enemy) or (not _hit.is_empty() and is_same(enemy, _hit.back())):
			continue
		var distance := enemy.global_position.distance_to(global_position)
		var fresh := not _hit.has(enemy)
		if distance > bounce_range or (best_fresh and not fresh):
			continue
		if (fresh and not best_fresh) or distance < best_distance:
			best = enemy
			best_fresh = fresh
			best_distance = distance
	return best

# Untyped on purpose: a typed Enemy argument errors on a freed target before the check runs.
func _is_alive(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.health.is_dead
