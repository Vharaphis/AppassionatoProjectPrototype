class_name RusherBehavior
extends EnemyBehavior

## Chases, then stops, draws its dash line on the ground and dashes through the
## spot where the player was when the windup started. The dash does not home,
## goes through other enemies (only walls stop it) and overshoots the target.

enum State { CHASE, WINDUP, DASH, RECOVER }

## Collision mask while dashing: world only, so enemies and the player do not block it.
const DASH_MASK := 1

@export var dash_cooldown: float = 3.5
@export var windup_time: float = 0.6
@export var dash_speed: float = 22.0
## The dash goes this far past the player's position.
@export var dash_overshoot: float = 4.0
@export var dash_max_distance: float = 18.0
@export var recover_time: float = 0.6
@export var dash_min_range: float = 4.0
@export var dash_max_range: float = 14.0
@export var dash_contact_damage: int = 15
@export var telegraph_color: Color = Color(1.0, 1.0, 1.0, 0.7)
@export var line_color: Color = Color(1.0, 0.3, 0.1, 0.55)
@export var line_width: float = 0.8

var state: State = State.CHASE
var _timer: float = 0.0
var _cooldown_left: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _dash_distance: float = 0.0
var _normal_mask: int = 0
var _line: MeshInstance3D

func _ready() -> void:
	_cooldown_left = dash_cooldown
	_line = MeshInstance3D.new()
	_line.top_level = true
	_line.visible = false
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = line_color
	var mesh := BoxMesh.new()
	mesh.material = material
	_line.mesh = mesh
	get_parent().add_child.call_deferred(_line)

func physics_step(enemy: Enemy, delta: float) -> Vector3:
	_timer -= delta
	match state:
		State.CHASE:
			_cooldown_left -= delta
			var distance := enemy.distance_to_target()
			if _cooldown_left <= 0.0 and distance >= dash_min_range and distance <= dash_max_range:
				_dash_direction = enemy.direction_to_target()
				_dash_distance = minf(distance + dash_overshoot, dash_max_distance)
				_show_line(enemy)
				_enter(State.WINDUP, windup_time)
				return Vector3.ZERO
			return enemy.direction_to_target() * enemy.data.move_speed
		State.WINDUP:
			# Blink so the windup reads even at the edge of the screen.
			enemy.set_tint(telegraph_color if fmod(_timer, 0.15) > 0.075 else Color.TRANSPARENT)
			if _timer <= 0.0:
				enemy.clear_tint()
				_line.visible = false
				_normal_mask = enemy.collision_mask
				enemy.collision_mask = DASH_MASK
				_enter(State.DASH, _dash_distance / dash_speed)
			return Vector3.ZERO
		State.DASH:
			if _timer <= 0.0 or enemy.is_on_wall():
				enemy.collision_mask = _normal_mask
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

## Flat strip on the ground covering the whole dash, shown during the windup.
func _show_line(enemy: Enemy) -> void:
	(_line.mesh as BoxMesh).size = Vector3(line_width, 0.02, _dash_distance)
	var start := Vector3(enemy.global_position.x, 0.03, enemy.global_position.z)
	_line.global_transform = Transform3D(Basis.looking_at(_dash_direction), start + _dash_direction * _dash_distance / 2.0)
	_line.visible = true

func _enter(new_state: State, duration: float) -> void:
	state = new_state
	_timer = duration
