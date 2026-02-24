extends RefCounted
## Tests for EventBus (scripts/autoload/event_bus.gd)
## Verifies all expected signals are declared.

var EB: Object
var _eb_script: GDScript

const EXPECTED_SIGNALS: Array = [
	# Player events
	"player_damaged",
	"player_healed",
	"player_died",
	"player_respawned",
	"player_leveled_up",
	"player_xp_gained",
	# Enemy events
	"enemy_damaged",
	"enemy_died",
	"enemy_spawned",
	# Loot events
	"loot_dropped",
	"loot_picked_up",
	"inventory_changed",
	# Extraction events
	"extraction_zone_entered",
	"extraction_zone_exited",
	"extraction_started",
	"extraction_completed",
	"extraction_cancelled",
	# Dungeon events
	"floor_changed",
	"dungeon_generated",
	"stairs_entered",
	# PvP events
	"pvp_kill",
	"pvp_damage",
	# UI events
	"show_damage_number",
	"show_notification",
	"ui_mode_changed",
]


func _init() -> void:
	_eb_script = load("res://scripts/autoload/event_bus.gd")


func before_each() -> void:
	EB = _eb_script.new()


func test_all_player_signals_exist() -> Dictionary:
	var player_signals := ["player_damaged", "player_healed", "player_died", "player_respawned", "player_leveled_up", "player_xp_gained"]
	return _check_signals(player_signals, "player")


func test_all_enemy_signals_exist() -> Dictionary:
	var enemy_signals := ["enemy_damaged", "enemy_died", "enemy_spawned"]
	return _check_signals(enemy_signals, "enemy")


func test_all_loot_signals_exist() -> Dictionary:
	var loot_signals := ["loot_dropped", "loot_picked_up", "inventory_changed"]
	return _check_signals(loot_signals, "loot")


func test_all_extraction_signals_exist() -> Dictionary:
	var extraction_signals := ["extraction_zone_entered", "extraction_zone_exited", "extraction_started", "extraction_completed", "extraction_cancelled"]
	return _check_signals(extraction_signals, "extraction")


func test_all_dungeon_signals_exist() -> Dictionary:
	var dungeon_signals := ["floor_changed", "dungeon_generated", "stairs_entered"]
	return _check_signals(dungeon_signals, "dungeon")


func test_all_pvp_signals_exist() -> Dictionary:
	var pvp_signals := ["pvp_kill", "pvp_damage"]
	return _check_signals(pvp_signals, "pvp")


func test_all_ui_signals_exist() -> Dictionary:
	var ui_signals := ["show_damage_number", "show_notification", "ui_mode_changed"]
	return _check_signals(ui_signals, "ui")


func _check_signals(signal_names: Array, category: String) -> Dictionary:
	var sig_list := EB.get_signal_list()
	var declared_names: Array[String] = []
	for s in sig_list:
		declared_names.append(s["name"])
	for sig_name in signal_names:
		if sig_name not in declared_names:
			return {"passed": false, "message": "%s signal '%s' not declared" % [category, sig_name]}
	return {"passed": true, "message": ""}
