extends RefCounted
## Tests for PauseMenu (scripts/ui/pause_menu.gd)

var _script: GDScript


func _init() -> void:
	_script = load("res://scripts/ui/pause_menu.gd")


func test_pause_menu_loadable() -> Dictionary:
	if _script == null:
		return {"passed": false, "message": "pause_menu.gd failed to load"}
	return {"passed": true, "message": ""}


func test_menu_has_quit_to_town() -> Dictionary:
	var instance = _script.new()
	var items: Array = instance.MENU_ITEMS
	if "Quit to Town" not in items:
		return {"passed": false, "message": "MENU_ITEMS should contain 'Quit to Town', got: %s" % str(items)}
	return {"passed": true, "message": ""}


func test_menu_has_four_items() -> Dictionary:
	var instance = _script.new()
	var items: Array = instance.MENU_ITEMS
	if items.size() != 4:
		return {"passed": false, "message": "Expected 4 menu items, got %d" % items.size()}
	return {"passed": true, "message": ""}


func test_menu_first_item_is_resume() -> Dictionary:
	var instance = _script.new()
	var items: Array = instance.MENU_ITEMS
	if items[0] != "Resume":
		return {"passed": false, "message": "First item should be 'Resume', got '%s'" % items[0]}
	return {"passed": true, "message": ""}
