class_name DashEffect
extends CardEffect

## Dashes the player towards the mouse, then plays `on_end` where it stopped.
## The distance is scaled by Ampli.

const PREVIEW_COLOR := Color(0.3, 0.8, 1.0, 0.4)

@export var distance: float = 4.0
@export var duration: float = 0.15
## Played when the dash ends (e.g. a Berserk shockwave).
@export var on_end: Array[CardEffect] = []

func execute(ctx: EffectContext) -> void:
	if ctx.player == null:
		return
	var player := ctx.player
	player.dash(player.get_mouse_direction(), distance * ctx.effect_multiplier, duration)
	if on_end.is_empty():
		return
	await player.dash_finished
	# shortcut: ctx is shared, reused if another card plays during the dash (0.15 s); fine while slots last > 1 s.
	for effect in on_end:
		if effect:
			effect.execute(ctx)

## Arrow on the floor from the player to where the dash will land, following the
## mouse until the card plays.
func preview(ctx: EffectContext, preview_duration: float) -> void:
	if ctx.player == null:
		return
	var player := ctx.player
	var arrow := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 0.05, distance)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = PREVIEW_COLOR
	box.material = material
	arrow.mesh = box
	player.get_parent().add_child(arrow)
	var follow := func(_t: float) -> void:
		if not is_instance_valid(player):
			return
		var direction := player.get_mouse_direction()
		arrow.global_position = player.global_position + direction * distance / 2.0 + Vector3.UP * 0.05
		arrow.rotation.y = atan2(direction.x, direction.z)
	follow.call(0.0)
	arrow.create_tween().tween_method(follow, 0.0, 1.0, preview_duration).finished.connect(arrow.queue_free)
