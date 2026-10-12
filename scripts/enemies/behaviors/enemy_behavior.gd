@abstract
class_name EnemyBehavior
extends Node

## How an enemy moves. Child node of the Enemy, which delegates its movement
## to it so a new enemy type needs a new behaviour, not a new enemy script.

## Returns the velocity the enemy wants this physics frame.
@abstract func physics_step(enemy: Enemy, delta: float) -> Vector3

## Direction the enemy should face. Vector3.ZERO = face where it moves.
func get_facing(_enemy: Enemy) -> Vector3:
	return Vector3.ZERO

## Contact damage dealt to the player right now.
func get_contact_damage(enemy: Enemy) -> int:
	return enemy.data.contact_damage
