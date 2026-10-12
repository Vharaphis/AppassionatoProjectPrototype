class_name Projectile
extends Area3D

## Straight-line enemy shot. Layer 4 (enemy projectiles), detects the world and
## the player body; freed on hit, on a wall or when its lifetime runs out.

const GROUP := &"enemy_projectiles"

@export var speed: float = 9.0
@export var damage: int = 8
@export var lifetime: float = 4.0

var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	add_to_group(GROUP)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		(body as Player).health.take_damage(damage)
	queue_free()
