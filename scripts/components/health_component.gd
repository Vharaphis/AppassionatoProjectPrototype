extends Node
class_name HealthComponent

signal health_changed(current: int, maximum: int)
signal armor_changed(current: int)
signal damaged(amount: int)
signal died

@export var max_health: int = 100
## Seconds during which further damage is ignored after being hit (0 = none).
@export var invulnerability_duration: float = 0.0

var current_health: int
## Absorbs incoming damage before health. Granted by cards.
var armor: int = 0
var is_dead: bool = false

var _invulnerability_left: float = 0.0

func _ready() -> void:
	current_health = max_health

func _physics_process(delta: float) -> void:
	if _invulnerability_left > 0.0:
		_invulnerability_left = maxf(_invulnerability_left - delta, 0.0)

func is_invulnerable() -> bool:
	return _invulnerability_left > 0.0

## Returns true when the damage was actually applied.
func take_damage(amount: int) -> bool:
	if is_dead or amount <= 0 or is_invulnerable():
		return false
	var remaining := amount
	if armor > 0:
		var absorbed := mini(armor, remaining)
		armor -= absorbed
		remaining -= absorbed
		armor_changed.emit(armor)
	current_health = maxi(current_health - remaining, 0)
	_invulnerability_left = invulnerability_duration
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		is_dead = true
		died.emit()
	return true

func add_armor(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	armor += amount
	armor_changed.emit(armor)

func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
