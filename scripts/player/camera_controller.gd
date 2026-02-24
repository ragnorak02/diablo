class_name CameraController
extends Camera3D
## Isometric-style camera that follows the player. Diablo-like top-down angle.

@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 25, 18)
@export var follow_speed: float = 8.0
@export var look_ahead: float = 2.0

var _shake_amount: float = 0.0
var _shake_timer: float = 0.0


func _ready() -> void:
	# Set up isometric perspective
	fov = 35.0
	current = true
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.enemy_died.connect(_on_enemy_died)


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	# Follow target with offset
	var target_pos := target.global_position + offset

	# Look-ahead based on target velocity
	if target is CharacterBody3D:
		var vel: Vector3 = target.velocity
		target_pos += Vector3(vel.x, 0, vel.z).normalized() * look_ahead * vel.length() / 10.0

	global_position = global_position.lerp(target_pos, follow_speed * delta)

	# Always look at target
	look_at(target.global_position + Vector3(0, 1, 0))

	# Camera shake
	if _shake_timer > 0:
		_shake_timer -= delta
		var shake_offset := Vector3(
			randf_range(-_shake_amount, _shake_amount),
			randf_range(-_shake_amount, _shake_amount),
			randf_range(-_shake_amount, _shake_amount)
		)
		global_position += shake_offset
		_shake_amount = lerpf(_shake_amount, 0.0, 5.0 * delta)


func shake(amount: float = 0.3, duration: float = 0.2) -> void:
	_shake_amount = amount
	_shake_timer = duration


func _on_player_damaged(_pid: int, amount: float, _source: Node) -> void:
	shake(clampf(amount * 0.01, 0.1, 0.5), 0.15)


func _on_enemy_died(_enemy: Node, _killer: Node) -> void:
	shake(0.1, 0.1)
