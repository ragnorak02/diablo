class_name IsoTileGrid
extends Node2D
## Procedural isometric floor tile generator. Creates diamond polygon tiles in a checkerboard grid.

@export var grid_width: int = 16
@export var grid_height: int = 16
@export var tile_size: float = 32.0
@export var tile_color: Color = Color(0.25, 0.22, 0.18)
@export var tile_color_alt: Color = Color(0.20, 0.17, 0.14)

# Same isometric projection matrix used by the player controller
const ISO_X := Vector2(1.0, 0.5)
const ISO_Y := Vector2(-1.0, 0.5)


func _ready() -> void:
	_generate_tiles()


func _generate_tiles() -> void:
	for y in grid_height:
		for x in grid_width:
			var color: Color = tile_color if (x + y) % 2 == 0 else tile_color_alt
			var tile := Polygon2D.new()

			# Diamond shape: top, right, bottom, left
			var half := tile_size * 0.5
			tile.polygon = PackedVector2Array([
				Vector2(0, -half),    # top
				Vector2(half, 0),     # right
				Vector2(0, half),     # bottom
				Vector2(-half, 0),    # left
			])
			tile.color = color

			# Position using isometric projection
			tile.position = Vector2(
				(x - y) * tile_size * 0.5,
				(x + y) * tile_size * 0.25
			)

			add_child(tile)


## Returns the world center of the grid in pixel coordinates.
func get_grid_center() -> Vector2:
	var cx := float(grid_width) * 0.5
	var cy := float(grid_height) * 0.5
	return Vector2(
		(cx - cy) * tile_size * 0.5,
		(cx + cy) * tile_size * 0.25
	)


## Returns the world position for a grid coordinate.
func grid_to_world(gx: int, gy: int) -> Vector2:
	return Vector2(
		(gx - gy) * tile_size * 0.5,
		(gx + gy) * tile_size * 0.25
	)
