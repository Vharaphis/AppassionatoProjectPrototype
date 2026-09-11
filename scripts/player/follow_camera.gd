extends Camera3D
class_name FollowCamera

@export var target: Node3D
## Camera position relative to the target (top-down, slightly tilted).
@export var offset: Vector3 = Vector3(0.0, 18.0, 8.0)
## Higher = snappier. 0 disables smoothing.
@export var smoothing: float = 10.0

func _ready() -> void:
	if target == null:
		return
	var target_position := target.global_position
	look_at_from_position(target_position + offset, target_position, Vector3.UP)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var desired := target.get_global_transform_interpolated().origin + offset
	if smoothing <= 0.0:
		global_position = desired
	else:
		global_position = global_position.lerp(desired, 1.0 - exp(-smoothing * delta))
