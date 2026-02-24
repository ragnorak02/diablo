extends RefCounted
## Tests for HUD (scripts/ui/hud.gd)

var _script: GDScript


func _init() -> void:
	_script = load("res://scripts/ui/hud.gd")


func test_hud_loadable() -> Dictionary:
	if _script == null:
		return {"passed": false, "message": "hud.gd failed to load"}
	return {"passed": true, "message": ""}


func test_hud_has_set_location_text() -> Dictionary:
	var instance = _script.new()
	if not instance.has_method("set_location_text"):
		return {"passed": false, "message": "HUD missing set_location_text method"}
	return {"passed": true, "message": ""}


func test_hud_has_extraction_methods() -> Dictionary:
	var instance = _script.new()
	if not instance.has_method("show_extraction_progress"):
		return {"passed": false, "message": "HUD missing show_extraction_progress"}
	if not instance.has_method("hide_extraction_progress"):
		return {"passed": false, "message": "HUD missing hide_extraction_progress"}
	return {"passed": true, "message": ""}
