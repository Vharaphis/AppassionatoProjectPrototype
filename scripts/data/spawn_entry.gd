class_name SpawnEntry
extends Resource

## One line of a SpawnTable: which enemy, from which round, and how likely.

@export var enemy: EnemyData
## First round where this enemy can spawn.
@export var min_round: int = 1
## Weight at `min_round`.
@export var base_weight: float = 10.0
## Added each round after `min_round` (may be negative).
@export var weight_per_round: float = 0.0
## Floor, so a decreasing weight never drops to nothing.
@export var min_weight: float = 0.0
@export var max_weight: float = 100.0
## Maximum alive at once. 0 = unlimited.
@export var max_alive: int = 0

func weight_at(round_index: int) -> float:
	if enemy == null or round_index < min_round:
		return 0.0
	return clampf(base_weight + weight_per_round * (round_index - min_round), min_weight, max_weight)
