class_name CombatObjective
extends Node

## Condition de fin de manche : tuer `kills_required` ennemis. Pure comptabilité,
## le nœud ne touche ni au spawner ni à la scène, il annonce seulement sa progression.

signal progress_changed(kills: int, required: int)
signal completed

## Spawner écouté. Chaque ennemi qu'il fait apparaître est suivi jusqu'à sa mort.
@export var spawner: EnemySpawner
@export var kills_required: int = 8

var kills: int = 0

var _completed: bool = false

func _ready() -> void:
	if spawner == null:
		push_warning("CombatObjective sans EnemySpawner : la manche ne se terminera jamais.")
		return
	spawner.enemy_spawned.connect(_on_enemy_spawned)

func is_completed() -> bool:
	return _completed

func _on_enemy_spawned(enemy: Enemy) -> void:
	enemy.died.connect(_on_enemy_died)

func _on_enemy_died(_enemy: Enemy) -> void:
	if _completed:
		return
	kills += 1
	progress_changed.emit(kills, kills_required)
	if kills >= kills_required:
		_completed = true
		completed.emit()
