class_name HUD
extends CanvasLayer
## Heads-up display — health, mana, XP, floor info, gold, potions, minimap indicator.

var _health_bar: ProgressBar
var _mana_bar: ProgressBar
var _xp_bar: ProgressBar
var _health_label: Label
var _mana_label: Label
var _level_label: Label
var _floor_label: Label
var _gold_label: Label
var _potion_label: Label
var _notification_label: Label
var _extraction_bar: ProgressBar
var _extraction_container: VBoxContainer
var _controller_hints: HBoxContainer
var _notification_timer: float = 0.0

# Damage numbers
var _damage_numbers: Array[Label] = []


func _ready() -> void:
	layer = 10
	_build_ui()
	_connect_signals()


func _process(delta: float) -> void:
	_update_bars()
	_update_labels()
	_update_notifications(delta)
	_update_damage_numbers(delta)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	add_child(margin)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_child(root)

	# --- Top bar ---
	var top := HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(top)

	# Health bar
	var health_vbox := _make_bar_group("HP", Color(0.8, 0.15, 0.15))
	_health_bar = health_vbox.get_node("Bar")
	_health_label = health_vbox.get_node("Label")
	top.add_child(health_vbox)

	# Mana bar
	var mana_vbox := _make_bar_group("MP", Color(0.15, 0.3, 0.85))
	_mana_bar = mana_vbox.get_node("Bar")
	_mana_label = mana_vbox.get_node("Label")
	top.add_child(mana_vbox)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	# Floor / Gold / Potions
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_SHRINK_END

	_floor_label = Label.new()
	_floor_label.text = "Floor 1"
	_floor_label.add_theme_font_size_override("font_size", 22)
	_floor_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	info_vbox.add_child(_floor_label)

	_gold_label = Label.new()
	_gold_label.text = "Gold: 0"
	_gold_label.add_theme_font_size_override("font_size", 18)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	info_vbox.add_child(_gold_label)

	_potion_label = Label.new()
	_potion_label.text = "Potions: 3/5"
	_potion_label.add_theme_font_size_override("font_size", 18)
	_potion_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	info_vbox.add_child(_potion_label)

	top.add_child(info_vbox)

	# --- XP bar (bottom-ish) ---
	var xp_spacer := Control.new()
	xp_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(xp_spacer)

	# Notification area
	_notification_label = Label.new()
	_notification_label.text = ""
	_notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification_label.add_theme_font_size_override("font_size", 24)
	_notification_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_notification_label.modulate.a = 0.0
	root.add_child(_notification_label)

	# Extraction progress
	_extraction_container = VBoxContainer.new()
	_extraction_container.visible = false
	_extraction_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var ext_label := Label.new()
	ext_label.text = "EXTRACTING..."
	ext_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ext_label.add_theme_font_size_override("font_size", 28)
	ext_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	_extraction_container.add_child(ext_label)

	_extraction_bar = ProgressBar.new()
	_extraction_bar.custom_minimum_size = Vector2(300, 25)
	_extraction_bar.max_value = 100.0
	var ext_style := StyleBoxFlat.new()
	ext_style.bg_color = Color(0.1, 0.4, 0.2)
	_extraction_bar.add_theme_stylebox_override("fill", ext_style)
	_extraction_container.add_child(_extraction_bar)
	root.add_child(_extraction_container)

	# XP bar
	var xp_container := HBoxContainer.new()
	_level_label = Label.new()
	_level_label.text = "Lv 1"
	_level_label.add_theme_font_size_override("font_size", 18)
	_level_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2))
	xp_container.add_child(_level_label)

	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(400, 12)
	_xp_bar.max_value = 100.0
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.8, 0.8, 0.1)
	_xp_bar.add_theme_stylebox_override("fill", xp_fill)
	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.15, 0.15, 0.1)
	_xp_bar.add_theme_stylebox_override("background", xp_bg)
	xp_container.add_child(_xp_bar)
	root.add_child(xp_container)

	# Controller hints bar
	_controller_hints = HBoxContainer.new()
	_controller_hints.alignment = BoxContainer.ALIGNMENT_CENTER
	_controller_hints.add_theme_constant_override("separation", 30)
	_add_hint("[A/LMB] Attack")
	_add_hint("[X/RMB] Heavy")
	_add_hint("[B/Space] Dodge")
	_add_hint("[Y/E] Interact")
	_add_hint("[LB/Q] Potion")
	_add_hint("[RB/1] Skill")
	_add_hint("[Menu/Esc] Pause")
	_add_hint("[Select/I] Inventory")
	root.add_child(_controller_hints)


func _make_bar_group(label_text: String, color: Color) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(250, 0)

	var label := Label.new()
	label.name = "Label"
	label.text = "%s: 100/100" % label_text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	vbox.add_child(label)

	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.custom_minimum_size = Vector2(250, 18)
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", fill)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.1, 0.1)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg)

	vbox.add_child(bar)
	return vbox


func _add_hint(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.5))
	_controller_hints.add_child(label)


func _update_bars() -> void:
	var pd: Dictionary = GameManager.player_data
	if _health_bar:
		_health_bar.max_value = pd.max_health
		_health_bar.value = pd.health
	if _mana_bar:
		_mana_bar.max_value = pd.max_mana
		_mana_bar.value = pd.mana
	if _xp_bar:
		_xp_bar.max_value = pd.xp_to_next
		_xp_bar.value = pd.xp


func set_location_text(text: String) -> void:
	if _floor_label:
		_floor_label.text = text


func _update_labels() -> void:
	var pd: Dictionary = GameManager.player_data
	if _health_label:
		_health_label.text = "HP: %d/%d" % [int(pd.health), int(pd.max_health)]
	if _mana_label:
		_mana_label.text = "MP: %d/%d" % [int(pd.mana), int(pd.max_mana)]
	if _level_label:
		_level_label.text = "Lv %d  " % pd.level
	if _floor_label and _floor_label.text.begins_with("Floor"):
		_floor_label.text = "Floor %d / %d" % [GameManager.current_floor, GameManager.total_floors]
	if _gold_label:
		_gold_label.text = "Gold: %d" % pd.gold
	if _potion_label:
		_potion_label.text = "Potions: %d/%d" % [pd.potions, pd.max_potions]


func _update_notifications(delta: float) -> void:
	if _notification_timer > 0:
		_notification_timer -= delta
		if _notification_timer <= 0:
			var tween := create_tween()
			tween.tween_property(_notification_label, "modulate:a", 0.0, 0.5)


func _update_damage_numbers(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in _damage_numbers.size():
		var label: Label = _damage_numbers[i]
		if is_instance_valid(label):
			label.modulate.a -= delta * 1.5
			label.position.y -= 40.0 * delta
			if label.modulate.a <= 0:
				label.queue_free()
				to_remove.append(i)
		else:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		_damage_numbers.remove_at(idx)


func show_extraction_progress(progress: float, total: float) -> void:
	_extraction_container.visible = true
	_extraction_bar.max_value = total
	_extraction_bar.value = progress


func hide_extraction_progress() -> void:
	_extraction_container.visible = false


func _connect_signals() -> void:
	EventBus.show_notification.connect(_on_show_notification)
	EventBus.show_damage_number.connect(_on_show_damage_number)
	EventBus.extraction_started.connect(func(_pid: int) -> void: _extraction_container.visible = true)
	EventBus.extraction_completed.connect(func(_pid: int, _loot: Array) -> void: _extraction_container.visible = false)
	EventBus.extraction_cancelled.connect(func(_pid: int) -> void: _extraction_container.visible = false)


func _on_show_notification(text: String, type: String) -> void:
	if not _notification_label:
		return
	_notification_label.text = text
	_notification_label.modulate.a = 1.0
	_notification_timer = 3.0

	match type:
		"boss":
			_notification_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		"level_up":
			_notification_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
		"extraction":
			_notification_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		"heal":
			_notification_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		"warning":
			_notification_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
		"skill":
			_notification_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
		_:
			_notification_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))


func _on_show_damage_number(world_pos: Vector3, amount: float, is_crit: bool) -> void:
	# Get camera to convert world pos to screen (3D only)
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	if camera.is_position_behind(world_pos):
		return

	var screen_pos := camera.unproject_position(world_pos)

	var label := Label.new()
	label.text = str(int(amount))
	label.position = screen_pos + Vector2(randf_range(-20, 20), randf_range(-10, 10))
	label.z_index = 100

	if is_crit:
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.1))
		label.text = str(int(amount)) + "!"
	else:
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))

	add_child(label)
	_damage_numbers.append(label)
