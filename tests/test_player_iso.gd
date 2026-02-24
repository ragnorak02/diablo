extends RefCounted
## Tests for PlayerIso (scripts/player/player_iso.gd)

var _script: GDScript


func _init() -> void:
	_script = load("res://scripts/player/player_iso.gd")


func test_player_iso_loadable() -> Dictionary:
	if _script == null:
		return {"passed": false, "message": "player_iso.gd failed to load"}
	return {"passed": true, "message": ""}


func test_player_iso_has_move_speed() -> Dictionary:
	# Check that the script has a move_speed property
	var props = _script.get_script_property_list()
	var has_speed = false
	for p in props:
		if p["name"] == "move_speed":
			has_speed = true
			break
	if not has_speed:
		return {"passed": false, "message": "PlayerIso missing move_speed property"}
	return {"passed": true, "message": ""}


func test_player_iso_default_speed() -> Dictionary:
	# Default move_speed should be 120.0
	var instance = _script.new()
	if instance.move_speed != 120.0:
		return {"passed": false, "message": "Expected move_speed 120.0, got %s" % str(instance.move_speed)}
	return {"passed": true, "message": ""}
