class_name InteractionZone
extends Area2D
## Reusable interaction zone. Shows a prompt when player overlaps, activates on confirm press.
## Emits zone_activated signal; optionally transitions scenes via exports.

signal zone_activated

@export var prompt_text: String = "Press [A] to interact"
@export var target_scene: String = ""

var _prompt_label: Label
var _player_inside: bool = false


func _ready() -> void:
	collision_layer = 32  # bit 6 — interaction
	collision_mask = 2    # bit 2 — detect player body

	_prompt_label = Label.new()
	_prompt_label.text = prompt_text
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 18)
	_prompt_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	_prompt_label.position = Vector2(-80, -50)
	_prompt_label.visible = false
	add_child(_prompt_label)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("attack_primary"):
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		zone_activated.emit()
		if target_scene != "":
			get_tree().change_scene_to_file(target_scene)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		_prompt_label.visible = false
