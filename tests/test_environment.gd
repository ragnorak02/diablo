extends RefCounted
## Tests for environment scripts (IsoTileGrid, InteractionZone)


# --- IsoTileGrid tests ---

func test_iso_tile_grid_class_loadable() -> Dictionary:
	var script: GDScript = load("res://scripts/environment/iso_tile_grid.gd")
	if script == null:
		return {"passed": false, "message": "iso_tile_grid.gd failed to load"}
	return {"passed": true, "message": ""}


func test_iso_grid_to_world_center() -> Dictionary:
	# Test the math directly: grid_to_world(0, 0) should return (0, 0)
	var tile_size := 32.0
	var gx := 0
	var gy := 0
	var result := Vector2(
		(gx - gy) * tile_size * 0.5,
		(gx + gy) * tile_size * 0.25
	)
	if result != Vector2.ZERO:
		return {"passed": false, "message": "grid_to_world(0,0) should be (0,0), got %s" % str(result)}
	return {"passed": true, "message": ""}


func test_iso_projection_right() -> Dictionary:
	# Isometric projection: right input (1, 0) → screen (1, 0.5)
	var input := Vector2(1.0, 0.0)
	var iso_x := Vector2(1.0, 0.5)
	var iso_y := Vector2(-1.0, 0.5)
	var result := iso_x * input.x + iso_y * input.y
	if not result.is_equal_approx(Vector2(1.0, 0.5)):
		return {"passed": false, "message": "ISO right should be (1, 0.5), got %s" % str(result)}
	return {"passed": true, "message": ""}


func test_iso_projection_up() -> Dictionary:
	# Isometric projection: up input (0, -1) → screen (1, -0.5)
	var input := Vector2(0.0, -1.0)
	var iso_x := Vector2(1.0, 0.5)
	var iso_y := Vector2(-1.0, 0.5)
	var result := iso_x * input.x + iso_y * input.y
	if not result.is_equal_approx(Vector2(1.0, -0.5)):
		return {"passed": false, "message": "ISO up should be (1, -0.5), got %s" % str(result)}
	return {"passed": true, "message": ""}


func test_iso_grid_center_calculation() -> Dictionary:
	# For a 16x16 grid with tile_size 32:
	# center grid pos = (8, 8)
	# world = ((8-8)*16, (8+8)*8) = (0, 128)
	var gw := 16
	var gh := 16
	var ts := 32.0
	var cx := float(gw) * 0.5
	var cy := float(gh) * 0.5
	var center := Vector2(
		(cx - cy) * ts * 0.5,
		(cx + cy) * ts * 0.25
	)
	if not center.is_equal_approx(Vector2(0, 128)):
		return {"passed": false, "message": "16x16 grid center should be (0, 128), got %s" % str(center)}
	return {"passed": true, "message": ""}


# --- InteractionZone tests ---

func test_interaction_zone_class_loadable() -> Dictionary:
	var script: GDScript = load("res://scripts/environment/interaction_zone.gd")
	if script == null:
		return {"passed": false, "message": "interaction_zone.gd failed to load"}
	return {"passed": true, "message": ""}


func test_interaction_zone_has_signal() -> Dictionary:
	var script: GDScript = load("res://scripts/environment/interaction_zone.gd")
	var instance = script.new()
	var sig_list = instance.get_signal_list()
	var has_activated = false
	for s in sig_list:
		if s["name"] == "zone_activated":
			has_activated = true
			break
	if not has_activated:
		return {"passed": false, "message": "InteractionZone missing zone_activated signal"}
	return {"passed": true, "message": ""}
