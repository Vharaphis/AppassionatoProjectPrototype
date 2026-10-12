class_name EnemyData
extends Resource

## Stats of an enemy type. The behaviour-specific settings live on the
## EnemyBehavior node of the scene, not here.

@export var id: StringName = &""
@export var display_name: String = ""
## Scene instantiated by the spawner. Its root must be an Enemy.
@export var scene: PackedScene
@export var max_health: int = 10
@export var move_speed: float = 3.5
@export var contact_damage: int = 10
@export var turn_speed: float = 10.0
