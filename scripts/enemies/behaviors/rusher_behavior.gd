class_name RusherBehavior
extends EnemyBehavior

## Chases, then stops, telegraphs and dashes in a straight line toward where the
## player was when the windup started. The dash does not home.

enum State { CHASE, WINDUP, DASH, RECOVER }

@export var dash_cooldown: float = 4.0
@export var windup_time: float = 0.6
@export var dash_speed: float = 12.0
@export var dash_duration: float = 0.5
@export var recover_time: float = 0.8
@export var dash_min_range: float = 4.0
@export var dash_max_range: float = 12.0
@export var dash_contact_damage: int = 15
@export var telegraph_color: Color = Color(1.0, 1.0, 1.0, 0.7)

var state: State = State.CHASE
var _timer: float = 0.0
var _cooldown_left: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	_cooldown_left = dash_cooldown

func physics_step(enemy: Enemy, delta: float) -> Vector3:
	_timer -= delta
	match state:
		State.CHASE:
			_cooldown_left -= delta
			var distance := enemy.distance_to_target()
			if _cooldown_left <= 0.0 and distance >= dash_min_range and distance <= dash_max_range:
				_dash_direction = enemy.direction_to_target()
				_enter(State.WINDUP, windup_time)
				return Vector3.ZERO
			return enemy.direction_to_target() * enemy.data.move_speed
		State.WINDUP:
			# Blink so the windup reads even at the edge of the screen.
			enemy.set_tint(telegraph_color if fmod(_timer, 0.15) > 0.075 else Color.TRANSPARENT)
			if _timer <= 0.0:
				enemy.clear_tint()
				_enter(State.DASH, dash_duration)
			return Vector3.ZERO
		State.DASH:
			if _timer <= 0.0 or enemy.is_on_wall():
				_enter(State.RECOVER, recover_time)
				return Vector3.ZERO
			return _dash_direction * dash_speed
		State.RECOVER:
			if _timer <= 0.0:
				_cooldown_left = dash_cooldown
				_enter(State.CHASE, 0.0)
			return Vector3.ZERO
	return Vector3.ZERO

func get_facing(enemy: Enemy) -> Vector3:
	if state == State.WINDUP or state == State.DASH:
		return _dash_direction
	return Vector3.ZERO if state == State.CHASE else enemy.get_forward()

func get_contact_damage(enemy: Enemy) -> int:
	return dash_contact_damage if state == State.DASH else enemy.data.contact_damage

func _enter(new_state: State, duration: float) -> void:
	state = new_state
	_timer = duration
