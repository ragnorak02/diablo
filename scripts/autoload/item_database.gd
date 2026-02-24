extends Node
## Item database singleton. Holds all item definitions and generates loot drops.

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum ItemType { WEAPON, ARMOR, POTION, TROPHY, GOLD, MATERIAL }

const RARITY_COLORS: Dictionary = {
	Rarity.COMMON: Color(0.7, 0.7, 0.7),
	Rarity.UNCOMMON: Color(0.2, 0.8, 0.2),
	Rarity.RARE: Color(0.3, 0.4, 1.0),
	Rarity.EPIC: Color(0.6, 0.2, 0.9),
	Rarity.LEGENDARY: Color(1.0, 0.65, 0.0),
}

const RARITY_NAMES: Dictionary = {
	Rarity.COMMON: "Common",
	Rarity.UNCOMMON: "Uncommon",
	Rarity.RARE: "Rare",
	Rarity.EPIC: "Epic",
	Rarity.LEGENDARY: "Legendary",
}

const RARITY_WEIGHTS: Array = [50.0, 25.0, 15.0, 8.0, 2.0]

var items: Dictionary = {}
var _next_uid: int = 0


func _ready() -> void:
	_register_items()


func _register_items() -> void:
	# --- Weapons ---
	_add_item("rusty_sword", {
		"name": "Rusty Sword",
		"type": ItemType.WEAPON,
		"rarity": Rarity.COMMON,
		"damage": 8.0,
		"attack_speed": 1.0,
		"description": "A worn blade. Still sharp enough.",
		"gold_value": 10,
	})
	_add_item("iron_sword", {
		"name": "Iron Sword",
		"type": ItemType.WEAPON,
		"rarity": Rarity.UNCOMMON,
		"damage": 14.0,
		"attack_speed": 1.0,
		"description": "Solid iron craftsmanship.",
		"gold_value": 35,
	})
	_add_item("shadow_blade", {
		"name": "Shadow Blade",
		"type": ItemType.WEAPON,
		"rarity": Rarity.RARE,
		"damage": 22.0,
		"attack_speed": 1.3,
		"description": "Forged in darkness, strikes like shadow.",
		"gold_value": 120,
	})
	_add_item("hellfire_axe", {
		"name": "Hellfire Axe",
		"type": ItemType.WEAPON,
		"rarity": Rarity.EPIC,
		"damage": 35.0,
		"attack_speed": 0.8,
		"description": "Burns with infernal flame.",
		"gold_value": 300,
	})
	_add_item("soulreaper", {
		"name": "Soulreaper",
		"type": ItemType.WEAPON,
		"rarity": Rarity.LEGENDARY,
		"damage": 50.0,
		"attack_speed": 1.1,
		"description": "Harvests the essence of slain foes.",
		"gold_value": 1000,
		"special": "lifesteal_10",
	})

	# --- Armor ---
	_add_item("leather_vest", {
		"name": "Leather Vest",
		"type": ItemType.ARMOR,
		"rarity": Rarity.COMMON,
		"defense": 5.0,
		"description": "Basic protection.",
		"gold_value": 8,
	})
	_add_item("chainmail", {
		"name": "Chainmail",
		"type": ItemType.ARMOR,
		"rarity": Rarity.UNCOMMON,
		"defense": 12.0,
		"description": "Linked rings of iron.",
		"gold_value": 40,
	})
	_add_item("plate_armor", {
		"name": "Plate Armor",
		"type": ItemType.ARMOR,
		"rarity": Rarity.RARE,
		"defense": 22.0,
		"description": "Heavy but sturdy plate.",
		"gold_value": 150,
	})
	_add_item("demon_shell", {
		"name": "Demon Shell",
		"type": ItemType.ARMOR,
		"rarity": Rarity.EPIC,
		"defense": 35.0,
		"description": "Scales from a fallen demon lord.",
		"gold_value": 350,
	})

	# --- Potions ---
	_add_item("health_potion", {
		"name": "Health Potion",
		"type": ItemType.POTION,
		"rarity": Rarity.COMMON,
		"heal_amount": 40.0,
		"description": "Restores 40 health.",
		"gold_value": 5,
		"stackable": true,
	})
	_add_item("mana_potion", {
		"name": "Mana Potion",
		"type": ItemType.POTION,
		"rarity": Rarity.COMMON,
		"mana_amount": 30.0,
		"description": "Restores 30 mana.",
		"gold_value": 5,
		"stackable": true,
	})

	# --- Trophies (Boss drops) ---
	_add_item("skeleton_kings_crown", {
		"name": "Skeleton King's Crown",
		"type": ItemType.TROPHY,
		"rarity": Rarity.LEGENDARY,
		"description": "The crown of the Skeleton King. Proof of victory.",
		"gold_value": 500,
		"boss": "skeleton_king",
	})
	_add_item("spider_queens_fang", {
		"name": "Spider Queen's Fang",
		"type": ItemType.TROPHY,
		"rarity": Rarity.EPIC,
		"description": "A venomous fang from the Spider Queen.",
		"gold_value": 300,
		"boss": "spider_queen",
	})

	# --- Materials ---
	_add_item("bone_fragment", {
		"name": "Bone Fragment",
		"type": ItemType.MATERIAL,
		"rarity": Rarity.COMMON,
		"description": "A piece of bone. Used in crafting.",
		"gold_value": 2,
		"stackable": true,
	})
	_add_item("dark_essence", {
		"name": "Dark Essence",
		"type": ItemType.MATERIAL,
		"rarity": Rarity.UNCOMMON,
		"description": "Concentrated dark energy.",
		"gold_value": 15,
		"stackable": true,
	})


func _add_item(id: String, data: Dictionary) -> void:
	data["id"] = id
	items[id] = data


func get_item(id: String) -> Dictionary:
	if items.has(id):
		return items[id].duplicate(true)
	push_warning("Item not found: %s" % id)
	return {}


func generate_uid() -> int:
	_next_uid += 1
	return _next_uid


func create_item_instance(id: String) -> Dictionary:
	var base := get_item(id)
	if base.is_empty():
		return {}
	base["uid"] = generate_uid()
	return base


func roll_rarity(floor_bonus: float = 0.0) -> int:
	var weights := RARITY_WEIGHTS.duplicate()
	# Higher floors shift rarity up
	weights[0] = maxf(weights[0] - floor_bonus * 5.0, 10.0)
	weights[2] += floor_bonus * 2.0
	weights[3] += floor_bonus * 1.0
	weights[4] += floor_bonus * 0.5

	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	var cumulative := 0.0
	for i in weights.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return i
	return Rarity.COMMON


func generate_loot_drop(floor_number: int, enemy_type: String = "") -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	var floor_bonus := float(floor_number) / float(GameManager.total_floors)

	# Gold drop
	var gold_amount := randi_range(5, 15) + floor_number * 3
	drops.append({
		"id": "gold",
		"type": ItemType.GOLD,
		"gold_value": gold_amount,
		"name": "%d Gold" % gold_amount,
	})

	# Chance for item drop
	var drop_chance := 0.3 + floor_bonus * 0.2
	if enemy_type == "boss":
		drop_chance = 1.0

	if randf() < drop_chance:
		var rarity := roll_rarity(floor_bonus)
		var candidates: Array = []
		for item_id in items:
			var item: Dictionary = items[item_id]
			if item.rarity == rarity and item.type != ItemType.TROPHY:
				candidates.append(item_id)
		if candidates.size() > 0:
			var chosen_id: String = candidates[randi() % candidates.size()]
			drops.append(create_item_instance(chosen_id))

	# Potion drop chance
	if randf() < 0.2:
		var potion_id := "health_potion" if randf() < 0.6 else "mana_potion"
		drops.append(create_item_instance(potion_id))

	# Material drop
	if randf() < 0.4:
		var mat_id := "bone_fragment" if randf() < 0.7 else "dark_essence"
		drops.append(create_item_instance(mat_id))

	return drops
