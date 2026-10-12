class_name SpawnTable
extends Resource

## Weighted list of the enemies a round can spawn.

@export var entries: Array[SpawnEntry] = []

## Weight of each entry this round, 0 for the excluded ones (before `min_round`
## or at `max_alive`). `alive_by_id` maps EnemyData.id to the number alive.
func weights_at(round_index: int, alive_by_id: Dictionary) -> Array[float]:
	var weights: Array[float] = []
	for entry in entries:
		var weight: float = entry.weight_at(round_index) if entry else 0.0
		if weight > 0.0 and entry.max_alive > 0 and alive_by_id.get(entry.enemy.id, 0) >= entry.max_alive:
			weight = 0.0
		weights.append(weight)
	return weights

## Picks an enemy for this round, null when every entry is excluded.
func pick(round_index: int, alive_by_id: Dictionary) -> EnemyData:
	var weights := weights_at(round_index, alive_by_id)
	var total := 0.0
	for weight in weights:
		total += weight
	if total <= 0.0:
		return null
	var roll := randf() * total
	for i in weights.size():
		if weights[i] <= 0.0:
			continue
		roll -= weights[i]
		if roll < 0.0:
			return entries[i].enemy
	# Float rounding can leave roll at ~0 after the loop: take the last valid entry.
	for i in range(weights.size() - 1, -1, -1):
		if weights[i] > 0.0:
			return entries[i].enemy
	return null
