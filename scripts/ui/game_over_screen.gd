class_name GameOverScreen
extends CanvasLayer
## Game over / victory screen showing run statistics.

var _title_label: Label
var _stats_label: Label
var _hint_label: Label
var _is_visible: bool = false


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	EventBus.player_died.connect(_on_player_died)
	EventBus.extraction_completed.connect(_on_extraction_completed)


func _input(event: InputEvent) -> void:
	if not _is_visible:
		return
	if event.is_action_pressed("attack_primary") or event.is_action_pressed("interact"):
		_restart()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.85)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(600, 500)
	vbox.position = Vector2(660, 290)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(_title_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override("font_size", 20)
	_stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.7))
	vbox.add_child(_stats_label)

	_hint_label = Label.new()
	_hint_label.text = "Press [A] or [E] to restart"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 18)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.5))
	vbox.add_child(_hint_label)


func _show_screen(title: String, title_color: Color) -> void:
	_is_visible = true
	visible = true
	get_tree().paused = true
	_title_label.text = title
	_title_label.add_theme_color_override("font_color", title_color)

	var s: Dictionary = GameManager.run_stats
	var time_str := "%02d:%02d" % [int(s.time_elapsed) / 60, int(s.time_elapsed) % 60]

	_stats_label.text = """
Time: %s
Floors Reached: %d
Enemies Killed: %d
PvP Kills: %d
Items Collected: %d
Gold Earned: %d
Damage Dealt: %d
Damage Taken: %d
""" % [time_str, GameManager.max_floor_reached, s.enemies_killed, s.pvp_kills,
		s.items_collected, s.gold_earned, int(s.damage_dealt), int(s.damage_taken)]


func _on_player_died(_player_id: int) -> void:
	_show_screen("YOU DIED", Color(0.9, 0.15, 0.1))


func _on_extraction_completed(_player_id: int, _loot: Array) -> void:
	_show_screen("EXTRACTION SUCCESSFUL", Color(0.2, 0.9, 0.4))


func _restart() -> void:
	_is_visible = false
	visible = false
	get_tree().paused = false
	GameManager.start_new_run()
	get_tree().reload_current_scene()
