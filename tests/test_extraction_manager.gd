extends RefCounted
## Tests for ExtractionManager (scripts/extraction/extraction_manager.gd)

var EM: Object
var _em_script: GDScript


func _init() -> void:
	_em_script = load("res://scripts/extraction/extraction_manager.gd")


func before_each() -> void:
	EM = _em_script.new()


# --- Initial state ---

func test_initial_not_extracting() -> Dictionary:
	if EM.is_extracting:
		return {"passed": false, "message": "Should not be extracting on init"}
	return {"passed": true, "message": ""}


func test_initial_progress_zero() -> Dictionary:
	if EM.extraction_progress != 0.0:
		return {"passed": false, "message": "Initial progress should be 0, got %s" % str(EM.extraction_progress)}
	return {"passed": true, "message": ""}


func test_initial_player_id() -> Dictionary:
	if EM.extracting_player_id != -1:
		return {"passed": false, "message": "Initial extracting_player_id should be -1, got %d" % EM.extracting_player_id}
	return {"passed": true, "message": ""}


# --- Constants ---

func test_extraction_time_positive() -> Dictionary:
	if EM.EXTRACTION_TIME <= 0.0:
		return {"passed": false, "message": "EXTRACTION_TIME should be > 0"}
	return {"passed": true, "message": ""}


func test_interrupt_range_positive() -> Dictionary:
	if EM.EXTRACTION_INTERRUPT_RANGE <= 0.0:
		return {"passed": false, "message": "EXTRACTION_INTERRUPT_RANGE should be > 0"}
	return {"passed": true, "message": ""}


# --- Cancel reset ---

func test_cancel_resets_state() -> Dictionary:
	EM.is_extracting = true
	EM.extraction_progress = 3.5
	EM.extracting_player_id = 1
	EM.cancel_extraction("test cancel")
	if EM.is_extracting:
		return {"passed": false, "message": "is_extracting should be false after cancel"}
	if EM.extraction_progress != 0.0:
		return {"passed": false, "message": "progress should be 0 after cancel, got %s" % str(EM.extraction_progress)}
	if EM.extracting_player_id != -1:
		return {"passed": false, "message": "extracting_player_id should be -1 after cancel"}
	return {"passed": true, "message": ""}


# --- Zone tracking ---

func test_zone_entered_tracks_player() -> Dictionary:
	EM._on_zone_entered(42)
	if not EM._player_in_zone.get(42, false):
		return {"passed": false, "message": "Player 42 should be tracked in zone"}
	return {"passed": true, "message": ""}


func test_zone_exited_untracks_player() -> Dictionary:
	EM._player_in_zone[7] = true
	EM._on_zone_exited(7)
	if EM._player_in_zone.get(7, true):
		return {"passed": false, "message": "Player 7 should not be in zone after exit"}
	return {"passed": true, "message": ""}


# --- Progress ---

func test_extraction_time_value() -> Dictionary:
	# Extraction time should be 5 seconds (game design constant)
	if EM.EXTRACTION_TIME != 5.0:
		return {"passed": false, "message": "Expected EXTRACTION_TIME 5.0, got %s" % str(EM.EXTRACTION_TIME)}
	return {"passed": true, "message": ""}
