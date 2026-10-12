class_name SwarmerBehavior
extends KeepDistanceBehavior

## Keeps its distance and periodically summons a small horde around itself.
## Minions bypass the spawn table and outlive their summoner.

enum State { MOVE, SUMMON }

@export var minion: EnemyData
@export var summon_interval: float = 8.0
@export var minions_per_summon: int = 4
@export var summon_radius: float = 2.0
## Living minions of this swarmer at once.
@export var max_minions: int = 12
@export var telegraph_time: float = 0.5
@export var telegraph_color: Color = Color(1.0, 0.9, 0.3, 0.8)

var state: State = State.MOVE
var _timer: float = 0.0
var _minions: Array[Enemy] = []

func _ready() -> void:
	super()
	_timer = summon_interval

func physics_step(enemy: Enemy, delta: float) -> Vector3:
	_timer -= delta
	match state:
		State.MOVE:
			if _timer <= 0.0:
				state = State.SUMMON
				_timer = telegraph_time
				enemy.set_tint(telegraph_color)
		State.SUMMON:
			if _timer <= 0.0:
				enemy.clear_tint()
				_summon(enemy)
				state = State.MOVE
				_timer = summon_interval
			return Vector3.ZERO
	return super(enemy, delta)

func _summon(enemy: Enemy) -> void:
	if minion == null or enemy.spawner == null:
		return
	var alive: Array[Enemy] = []
	for m in _minions:
		if is_instance_valid(m) and not m.is_queued_for_deletion():
			alive.append(m)
	_minions = alive
	var count := mini(minions_per_summon, max_minions - _minions.size())
	for i in count:
		var angle := TAU * i / count + randf() * 0.5
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * summon_radius
		var spawned := enemy.spawner.add_enemy(minion, enemy.global_position + offset)
		if spawned:
			_minions.append(spawned)
