class_name LootDrop
extends Area3D
## Physical loot drop in the world. Players walk over to pick up.

var item_data: Dictionary = {}
var _mesh: MeshInstance3D
var _label: Label3D
var _bob_time: float = 0.0
var _initial_y: float = 0.0


func _ready() -> void:
	collision_layer = 16  # loot layer
	collision_mask = 2  # player layer
	monitoring = false
	monitorable = true

	_setup_visual()
	_setup_collision()

	body_entered.connect(_on_body_entered)
	monitoring = true


func init(data: Dictionary, pos: Vector3) -> void:
	item_data = data
	global_position = pos
	_initial_y = pos.y + 0.5


func _setup_visual() -> void:
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.3)
	_mesh.mesh = box

	var mat := StandardMaterial3D.new()
	var rarity: int = item_data.get("rarity", 0)
	mat.albedo_color = ItemDatabase.RARITY_COLORS.get(rarity, Color.WHITE)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.8
	_mesh.material_override = mat
	_mesh.position.y = 0.5
	add_child(_mesh)

	# Name label
	_label = Label3D.new()
	_label.text = item_data.get("name", "Item")
	_label.font_size = 32
	_label.modulate = ItemDatabase.RARITY_COLORS.get(rarity, Color.WHITE)
	_label.position.y = 1.2
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	add_child(_label)


func _setup_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.0
	col.shape = shape
	col.position.y = 0.5
	add_child(col)


func _process(delta: float) -> void:
	_bob_time += delta * 2.0
	if _mesh:
		_mesh.position.y = _initial_y + sin(_bob_time) * 0.15
		_mesh.rotation.y += delta * 1.5


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var pid: int = body.get("player_id") if body.get("player_id") != null else 0
		_pick_up(pid)


func _pick_up(player_id: int) -> void:
	var item_type: int = item_data.get("type", -1)

	if item_type == ItemDatabase.ItemType.GOLD:
		GameManager.player_data.gold += item_data.get("gold_value", 0)
	elif item_type == ItemDatabase.ItemType.POTION:
		if GameManager.player_data.potions < GameManager.player_data.max_potions:
			GameManager.player_data.potions += 1
		else:
			EventBus.show_notification.emit("Potions full!", "warning")
			return
	else:
		GameManager.player_data.inventory.append(item_data)

	EventBus.loot_picked_up.emit(player_id, item_data)
	queue_free()
