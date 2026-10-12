class_name AreaFlash
extends RefCounted

## Brief flat shape drawn on the floor so the player sees where an attack hit.

const DURATION := 0.25
const HEIGHT := 0.05
const SEGMENTS := 24

## Sector of `angle_deg` degrees (360 = full circle) centered on `direction`.
static func sector(parent: Node, center: Vector3, direction: Vector3, angle_deg: float, radius: float, color: Color) -> MeshInstance3D:
	if parent == null or radius <= 0.0:
		return null
	var base_angle := atan2(direction.x, direction.z)
	var half := deg_to_rad(clampf(angle_deg, 1.0, 360.0)) / 2.0
	var vertices := PackedVector3Array()
	for i in SEGMENTS:
		var a0 := base_angle - half + 2.0 * half * i / SEGMENTS
		var a1 := base_angle - half + 2.0 * half * (i + 1) / SEGMENTS
		vertices.append_array([Vector3.ZERO, Vector3(sin(a1), 0.0, cos(a1)) * radius, Vector3(sin(a0), 0.0, cos(a0)) * radius])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	parent.add_child(instance)
	instance.global_position = Vector3(center.x, HEIGHT, center.z)
	instance.create_tween().tween_property(material, "albedo_color:a", 0.0, DURATION).finished.connect(instance.queue_free)
	return instance
