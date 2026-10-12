@abstract
class_name EnemyBehavior
extends Node

## How an enemy moves. Child node of the Enemy, which delegates its movement
## to it so a new enemy type needs a new behaviour, not a new enemy script.

## Returns the velocity the enemy wants this physics frame.
@abstract func physics_step(enemy: Enemy, delta: float) -> Vector3
