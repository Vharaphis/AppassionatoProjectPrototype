@tool
extends Node3D
class_name Level

## Inner playable size of the arena on the X/Z plane, in meters.
@export var arena_size: Vector2 = Vector2(60.0, 40.0):
	set(value):
		arena_size = value.max(Vector2(4.0, 4.0))
		_update_geometry()
@export var wall_height: float = 2.0:
	set(value):
		wall_height = maxf(value, 0.1)
		_update_geometry()
@export var wall_thickness: float = 1.0:
	set(value):
		wall_thickness = maxf(value, 0.1)
		_update_geometry()

func _ready() -> void:
	_update_geometry()

## Playable rectangle in global X/Z coordinates (x = X axis, y = Z axis).
func get_playable_rect() -> Rect2:
	var center := Vector2(global_position.x, global_position.z)
	return Rect2(center - arena_size / 2.0, arena_size)

func _update_geometry() -> void:
	if not is_node_ready():
		return
	var half := arena_size / 2.0
	var outer_width := arena_size.x + wall_thickness * 2.0

	_resize_box($Floor, Vector3(outer_width, 1.0, arena_size.y + wall_thickness * 2.0), Vector3(0.0, -0.5, 0.0))
	_resize_box($WallNorth, Vector3(outer_width, wall_height, wall_thickness), Vector3(0.0, wall_height / 2.0, -half.y - wall_thickness / 2.0))
	_resize_box($WallSouth, Vector3(outer_width, wall_height, wall_thickness), Vector3(0.0, wall_height / 2.0, half.y + wall_thickness / 2.0))
	_resize_box($WallWest, Vector3(wall_thickness, wall_height, arena_size.y), Vector3(-half.x - wall_thickness / 2.0, wall_height / 2.0, 0.0))
	_resize_box($WallEast, Vector3(wall_thickness, wall_height, arena_size.y), Vector3(half.x + wall_thickness / 2.0, wall_height / 2.0, 0.0))

func _resize_box(body: StaticBody3D, size: Vector3, center: Vector3) -> void:
	if body == null:
		return
	body.position = center
	var mesh_instance := body.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_instance and mesh_instance.mesh is BoxMesh:
		(mesh_instance.mesh as BoxMesh).size = size
	var collision := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision and collision.shape is BoxShape3D:
		(collision.shape as BoxShape3D).size = size
