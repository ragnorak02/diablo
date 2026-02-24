class_name PauseMenu
extends CanvasLayer
## Pause menu with resume, restart, quit options.

var _is_open: bool = false
var _selected: int = 0
var _buttons: Array[Label] = []
var _panel: PanelContainer

const MENU_ITEMS: Array[String] = ["Resume", "Quit to Town", "Restart Run", "Quit to Desktop"]


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		toggle()
		get_viewport().set_input_as_handled()

	if not _is_open:
		return

	if event.is_action_pressed("ui_nav_up") or event.is_action_pressed("ui_up"):
		_selected = (_selected - 1 + MENU_ITEMS.size()) % MENU_ITEMS.size()
		_update_selection()
		AudioManager.play_ui("ui_navigate")
	elif event.is_action_pressed("ui_nav_down") or event.is_action_pressed("ui_down"):
		_selected = (_selected + 1) % MENU_ITEMS.size()
		_update_selection()
		AudioManager.play_ui("ui_navigate")
	elif event.is_action_pressed("attack_primary") or event.is_action_pressed("interact"):
		AudioManager.play_ui("ui_select")
		_activate_selected()


func toggle() -> void:
	_is_open = not _is_open
	visible = _is_open
	if _is_open:
		GameManager.pause_game()
		_selected = 0
		_update_selection()
	else:
		GameManager.resume_game()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.8)
	add_child(bg)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(400, 300)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(760, 390)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.08, 0.95)
	style.border_color = Color(0.8, 0.6, 0.2)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	_panel.add_child(margin)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	for item_text in MENU_ITEMS:
		var label := Label.new()
		label.text = item_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6))
		vbox.add_child(label)
		_buttons.append(label)


func _update_selection() -> void:
	for i in _buttons.size():
		if i == _selected:
			_buttons[i].add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			_buttons[i].text = "> " + MENU_ITEMS[i] + " <"
		else:
			_buttons[i].add_theme_color_override("font_color", Color(0.7, 0.7, 0.6))
			_buttons[i].text = MENU_ITEMS[i]


func _activate_selected() -> void:
	match _selected:
		0:  # Resume
			toggle()
		1:  # Quit to Town
			toggle()
			GameManager.go_to_town()
		2:  # Restart
			toggle()
			GameManager.start_new_run()
			get_tree().reload_current_scene()
		3:  # Quit to Desktop
			get_tree().quit()
