extends RefCounted
## Tests for GameManager (scripts/autoload/game_manager.gd)

var GM: Object  # GameManager instance (no autoload in --main-loop)
var _gm_script: GDScript


func _init() -> void:
	_gm_script = load("res://scripts/autoload/game_manager.gd")


func before_each() -> void:
	GM = _gm_script.new()


# --- State reset ---

func test_initial_state() -> Dictionary:
	if GM.state != 0:  # GameState.MENU == 0
		return {"passed": false, "message": "Expected state MENU(0), got %d" % GM.state}
	if GM.current_floor != 1:
		return {"passed": false, "message": "Expected floor 1, got %d" % GM.current_floor}
	if GM.is_run_active:
		return {"passed": false, "message": "Expected is_run_active false"}
	return {"passed": true, "message": ""}


func test_player_data_defaults() -> Dictionary:
	if GM.player_data.health != 100.0:
		return {"passed": false, "message": "Expected health 100, got %s" % str(GM.player_data.health)}
	if GM.player_data.level != 1:
		return {"passed": false, "message": "Expected level 1, got %d" % GM.player_data.level}
	if GM.player_data.potions != 3:
		return {"passed": false, "message": "Expected 3 potions, got %d" % GM.player_data.potions}
	if GM.player_data.stats.strength != 10:
		return {"passed": false, "message": "Expected strength 10, got %d" % GM.player_data.stats.strength}
	return {"passed": true, "message": ""}


func test_session_defaults_gold() -> Dictionary:
	if GM.player_data.gold != 0:
		return {"passed": false, "message": "Expected gold 0, got %d" % GM.player_data.gold}
	return {"passed": true, "message": ""}


func test_reset_player_data() -> Dictionary:
	GM.player_data.health = 50.0
	GM.player_data.level = 5
	GM.player_data.gold = 999
	GM._reset_player_data()
	if GM.player_data.health != 100.0:
		return {"passed": false, "message": "Health not reset: %s" % str(GM.player_data.health)}
	if GM.player_data.level != 1:
		return {"passed": false, "message": "Level not reset: %d" % GM.player_data.level}
	if GM.player_data.gold != 0:
		return {"passed": false, "message": "Gold not reset: %d" % GM.player_data.gold}
	return {"passed": true, "message": ""}


func test_reset_clears_inventory() -> Dictionary:
	GM.player_data.inventory.append({"name": "test"})
	GM._reset_player_data()
	if GM.player_data.inventory.size() != 0:
		return {"passed": false, "message": "Inventory not cleared after reset"}
	return {"passed": true, "message": ""}


# --- Floor clamping ---

func test_change_floor_up() -> Dictionary:
	GM.current_floor = 1
	GM.change_floor(1)
	if GM.current_floor != 2:
		return {"passed": false, "message": "Expected floor 2, got %d" % GM.current_floor}
	return {"passed": true, "message": ""}


func test_change_floor_clamps_below_1() -> Dictionary:
	GM.current_floor = 1
	GM.change_floor(-1)
	if GM.current_floor != 1:
		return {"passed": false, "message": "Floor went below 1: %d" % GM.current_floor}
	return {"passed": true, "message": ""}


func test_change_floor_clamps_above_max() -> Dictionary:
	GM.current_floor = GM.total_floors
	GM.change_floor(1)
	if GM.current_floor != GM.total_floors:
		return {"passed": false, "message": "Floor exceeded max: %d" % GM.current_floor}
	return {"passed": true, "message": ""}


func test_max_floor_reached_tracks() -> Dictionary:
	GM.current_floor = 1
	GM.max_floor_reached = 1
	GM.change_floor(1)
	GM.change_floor(1)
	if GM.max_floor_reached != 3:
		return {"passed": false, "message": "Expected max_floor_reached 3, got %d" % GM.max_floor_reached}
	return {"passed": true, "message": ""}


# --- XP formula ---

func test_xp_for_level_1() -> Dictionary:
	var xp = GM.get_xp_for_next_level(1)
	if xp != 100:
		return {"passed": false, "message": "Level 1 XP should be 100, got %d" % xp}
	return {"passed": true, "message": ""}


func test_xp_for_level_2() -> Dictionary:
	var xp = GM.get_xp_for_next_level(2)
	# 100 * 1.5^1 = 150
	if xp != 150:
		return {"passed": false, "message": "Level 2 XP should be 150, got %d" % xp}
	return {"passed": true, "message": ""}


func test_xp_scales_exponentially() -> Dictionary:
	var xp3 = GM.get_xp_for_next_level(3)
	var xp5 = GM.get_xp_for_next_level(5)
	if xp5 <= xp3:
		return {"passed": false, "message": "Level 5 XP (%d) should exceed level 3 (%d)" % [xp5, xp3]}
	return {"passed": true, "message": ""}


# --- Level-up stats ---

func test_level_up_increases_stats() -> Dictionary:
	var old_max_health = GM.player_data.max_health
	var old_str = GM.player_data.stats.strength
	GM._apply_level_up()
	if GM.player_data.max_health != old_max_health + 10.0:
		return {"passed": false, "message": "max_health should increase by 10"}
	if GM.player_data.stats.strength != old_str + 2:
		return {"passed": false, "message": "strength should increase by 2"}
	return {"passed": true, "message": ""}


func test_level_up_heals_to_full() -> Dictionary:
	GM.player_data.health = 50.0
	GM._apply_level_up()
	if GM.player_data.health != GM.player_data.max_health:
		return {"passed": false, "message": "Level up should heal to full, health=%s max=%s" % [str(GM.player_data.health), str(GM.player_data.max_health)]}
	return {"passed": true, "message": ""}


func test_level_up_increases_mana() -> Dictionary:
	var old_max_mana = GM.player_data.max_mana
	GM._apply_level_up()
	if GM.player_data.max_mana != old_max_mana + 5.0:
		return {"passed": false, "message": "max_mana should increase by 5, got %s" % str(GM.player_data.max_mana)}
	return {"passed": true, "message": ""}


# --- Pause / Resume ---

func test_pause_sets_state() -> Dictionary:
	GM.state = 1  # PLAYING
	GM.pause_game()
	if GM.state != 2:  # PAUSED
		return {"passed": false, "message": "Expected PAUSED(2), got %d" % GM.state}
	return {"passed": true, "message": ""}


func test_resume_from_paused() -> Dictionary:
	GM.state = 2  # PAUSED
	GM.resume_game()
	if GM.state != 1:  # PLAYING
		return {"passed": false, "message": "Expected PLAYING(1), got %d" % GM.state}
	return {"passed": true, "message": ""}


func test_pause_only_from_playing() -> Dictionary:
	GM.state = 0  # MENU
	GM.pause_game()
	if GM.state != 0:
		return {"passed": false, "message": "Pause should only work from PLAYING state"}
	return {"passed": true, "message": ""}


# --- Run stats ---

func test_reset_run_stats() -> Dictionary:
	GM.run_stats.enemies_killed = 10
	GM.run_stats.damage_dealt = 500.0
	GM._reset_run_stats()
	if GM.run_stats.enemies_killed != 0:
		return {"passed": false, "message": "enemies_killed not reset"}
	if GM.run_stats.damage_dealt != 0.0:
		return {"passed": false, "message": "damage_dealt not reset"}
	return {"passed": true, "message": ""}


# --- Scene navigation methods ---

func test_total_floors_default() -> Dictionary:
	if GM.total_floors != 10:
		return {"passed": false, "message": "Expected total_floors 10, got %d" % GM.total_floors}
	return {"passed": true, "message": ""}


func test_has_scene_navigation_methods() -> Dictionary:
	if not GM.has_method("go_to_town"):
		return {"passed": false, "message": "Missing go_to_town method"}
	if not GM.has_method("go_to_dungeon_entrance"):
		return {"passed": false, "message": "Missing go_to_dungeon_entrance method"}
	if not GM.has_method("go_to_dungeon_floor"):
		return {"passed": false, "message": "Missing go_to_dungeon_floor method"}
	return {"passed": true, "message": ""}
