class_name InventoryScreen
extends CanvasLayer
## Inventory screen. Shows collected items, equipment, stats.

var _panel: PanelContainer
var _item_list: VBoxContainer
var _stats_label: Label
var _is_open: bool = false
var _selected_index: int = 0


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	EventBus.inventory_changed.connect(_on_inventory_changed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle()
		get_viewport().set_input_as_handled()
		return

	if not _is_open:
		return

	# B / Escape closes when open
	if event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()
		return

	# Controller navigation in inventory
	if event.is_action_pressed("ui_nav_up") or event.is_action_pressed("ui_up"):
		_selected_index = maxi(_selected_index - 1, 0)
		_refresh_items()
		AudioManager.play_ui("ui_navigate")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_nav_down") or event.is_action_pressed("ui_down"):
		_selected_index = mini(_selected_index + 1, GameManager.player_data.inventory.size() - 1)
		_refresh_items()
		AudioManager.play_ui("ui_navigate")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("attack_primary"):
		_equip_selected()
		AudioManager.play_ui("ui_select")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("attack_secondary"):
		_drop_selected()
		AudioManager.play_ui("ui_select")
		get_viewport().set_input_as_handled()


func toggle() -> void:
	_is_open = not _is_open
	visible = _is_open
	if _is_open:
		_refresh_items()
		_refresh_stats()
		get_tree().paused = true
	else:
		get_tree().paused = false


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.75)
	add_child(bg)

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(800, 600)
	_panel.position = Vector2(560, 240)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.1, 0.95)
	panel_style.border_color = Color(0.8, 0.6, 0.2)
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	margin.add_child(hbox)

	# Left side: item list
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = "INVENTORY"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	left.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(400, 0)
	left.add_child(scroll)

	_item_list = VBoxContainer.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_item_list)

	var hints := Label.new()
	hints.text = "[A/LMB] Equip  |  [X/RMB] Drop  |  [B/Esc] Close  |  [I/Select] Close"
	hints.add_theme_font_size_override("font_size", 14)
	hints.add_theme_color_override("font_color", Color(0.5, 0.5, 0.4))
	left.add_child(hints)

	hbox.add_child(left)

	# Right side: stats
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(300, 0)

	var stats_title := Label.new()
	stats_title.text = "CHARACTER"
	stats_title.add_theme_font_size_override("font_size", 28)
	stats_title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	right.add_child(stats_title)

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 16)
	_stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.7))
	right.add_child(_stats_label)

	hbox.add_child(right)


func _refresh_items() -> void:
	for child in _item_list.get_children():
		child.queue_free()

	var inventory: Array = GameManager.player_data.inventory
	if inventory.is_empty():
		var empty := Label.new()
		empty.text = "No items"
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_item_list.add_child(empty)
		return

	for i in inventory.size():
		var item: Dictionary = inventory[i]
		var row := HBoxContainer.new()

		var name_label := Label.new()
		var item_name: String = item.get("name", "Unknown")
		var equipped_tag := " [E]" if item.get("equipped", false) else ""
		name_label.text = item_name + equipped_tag
		var rarity: int = item.get("rarity", 0)
		name_label.add_theme_color_override("font_color", ItemDatabase.RARITY_COLORS.get(rarity, Color.WHITE))
		name_label.add_theme_font_size_override("font_size", 18)
		row.add_child(name_label)

		# Selected highlight
		if i == _selected_index:
			var sel := StyleBoxFlat.new()
			sel.bg_color = Color(0.3, 0.25, 0.1, 0.5)
			row.add_theme_stylebox_override("panel", sel)
			name_label.text = "> " + name_label.text

		_item_list.add_child(row)


func _refresh_stats() -> void:
	var pd: Dictionary = GameManager.player_data
	var stats_text := ""
	stats_text += "Level: %d\n" % pd.level
	stats_text += "XP: %d / %d\n\n" % [pd.xp, pd.xp_to_next]
	stats_text += "Health: %d / %d\n" % [int(pd.health), int(pd.max_health)]
	stats_text += "Mana: %d / %d\n\n" % [int(pd.mana), int(pd.max_mana)]
	stats_text += "STR: %d\n" % pd.stats.strength
	stats_text += "DEX: %d\n" % pd.stats.dexterity
	stats_text += "VIT: %d\n" % pd.stats.vitality
	stats_text += "INT: %d\n\n" % pd.stats.intelligence
	stats_text += "Gold: %d\n" % pd.gold
	stats_text += "Potions: %d / %d\n" % [pd.potions, pd.max_potions]
	stats_text += "Trophies: %d\n" % pd.trophies.size()
	stats_text += "Items: %d\n" % pd.inventory.size()

	if _stats_label:
		_stats_label.text = stats_text


func _equip_selected() -> void:
	var inventory: Array = GameManager.player_data.inventory
	if _selected_index < 0 or _selected_index >= inventory.size():
		return

	var item: Dictionary = inventory[_selected_index]
	if item.has("damage") or item.has("defense"):
		# Unequip same type
		for other in inventory:
			if other.has("damage") == item.has("damage") and other.has("defense") == item.has("defense"):
				other["equipped"] = false
		item["equipped"] = true
		_refresh_items()
		_refresh_stats()


func _drop_selected() -> void:
	var inventory: Array = GameManager.player_data.inventory
	if _selected_index < 0 or _selected_index >= inventory.size():
		return

	var item: Dictionary = inventory[_selected_index]
	inventory.remove_at(_selected_index)
	_selected_index = mini(_selected_index, inventory.size() - 1)

	# Drop in world near player
	for player in get_tree().get_nodes_in_group("player"):
		EventBus.loot_dropped.emit(item, player.global_position + Vector3(randf_range(-2, 2), 0.5, randf_range(-2, 2)))
		break

	_refresh_items()
	_refresh_stats()


func _on_inventory_changed(_player_id: int) -> void:
	if _is_open:
		_refresh_items()
		_refresh_stats()
