class_name SpitterBehavior
extends KeepDistanceBehavior

## Keeps its distance and fires a slow projectile at where the player stands
## when the windup ends (no prediction: moving dodges it).

enum State { MOVE, WINDUP }

const PROJECTILE_SCENE := preload("res://scenes/enemies/projectile.tscn")

@export var fire_interval: float = 2.5
@export var fire_range: float = 18.0
@export var windup_time: float = 0.4
@export var projectile_speed: float = 9.0
@export var projectile_damage: int = 8
@export var telegraph_color: Color = Color(0.7, 1.0, 0.4, 0.7)

var state: State = State.MOVE
var _timer: float = 0.0

func _ready() -> void:
	super()
	# Shielders look for allies in this group.
	get_parent().add_to_group(&"ranged")
	_timer = fire_interval

func physics_step(enemy: Enemy, delta: float) -> Vector3:
	_timer -= delta
	match state:
		State.MOVE:
			if _timer <= 0.0 and enemy.distance_to_target() <= fire_range:
				state = State.WINDUP
				_timer = windup_time
				enemy.set_tint(telegraph_color)
		State.WINDUP:
			if _timer <= 0.0:
				enemy.clear_tint()
				_fire(enemy)
				state = State.MOVE
				_timer = fire_interval
	return super(enemy, delta)

func _fire(enemy: Enemy) -> void:
	var direction := enemy.direction_to_target()
	if direction == Vector3.ZERO:
		return
	var shot := PROJECTILE_SCENE.instantiate() as Projectile
	shot.direction = direction
	shot.speed = projectile_speed
	shot.damage = projectile_damage
	var container := enemy.get_parent() as Node3D
	shot.position = container.to_local(enemy.global_position + direction * 0.6 + Vector3.UP)
	container.add_child(shot)
