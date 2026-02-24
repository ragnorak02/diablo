class_name PlayerIso
extends CharacterBody2D
## Isometric 2D player controller for town and cathedral navigation.
## Lightweight movement-only controller — combat handled by 3D PlayerController.

@export var move_speed: float = 120.0

var _visual: Polygon2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2   # player
	collision_mask = 1    # environment walls

	_setup_collision()
	_setup_visual()


func _setup_collision() -> void:
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	add_child(col)


func _setup_visual() -> void:
	_visual = Polygon2D.new()
	# Diamond shape for isometric look
	_visual.polygon = PackedVector2Array([
		Vector2(0, -14),   # top
		Vector2(10, 0),    # right
		Vector2(0, 14),    # bottom
		Vector2(-10, 0),   # left
	])
	_visual.color = Color(0.25, 0.45, 0.85)
	add_child(_visual)

	# Inner highlight
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([
		Vector2(0, -8),
		Vector2(6, 0),
		Vector2(0, 8),
		Vector2(-6, 0),
	])
	inner.color = Color(0.4, 0.6, 1.0, 0.6)
	add_child(inner)


func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_forward", "move_back")

	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	# Apply isometric projection to input
	var iso_dir := Vector2(
		input_dir.x - input_dir.y,
		(input_dir.x + input_dir.y) * 0.5
	)

	velocity = iso_dir * move_speed
	move_and_slide()
