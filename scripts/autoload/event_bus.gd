extends Node
## Global event bus for decoupled communication between systems.

# Player events
signal player_damaged(player_id: int, amount: float, source: Node)
signal player_healed(player_id: int, amount: float)
signal player_died(player_id: int)
signal player_respawned(player_id: int)
signal player_leveled_up(player_id: int, new_level: int)
signal player_xp_gained(player_id: int, amount: int)

# Enemy events
signal enemy_damaged(enemy: Node, amount: float, source: Node)
signal enemy_died(enemy: Node, killer: Node)
signal enemy_spawned(enemy: Node)

# Loot events
signal loot_dropped(item_data: Dictionary, position: Vector3)
signal loot_picked_up(player_id: int, item_data: Dictionary)
signal inventory_changed(player_id: int)

# Extraction events
signal extraction_zone_entered(player_id: int)
signal extraction_zone_exited(player_id: int)
signal extraction_started(player_id: int)
signal extraction_completed(player_id: int, loot: Array)
signal extraction_cancelled(player_id: int)

# Dungeon events
signal floor_changed(floor_number: int)
signal dungeon_generated(total_floors: int)
signal stairs_entered(direction: String, floor: int)

# PvP events
signal pvp_kill(killer_id: int, victim_id: int)
signal pvp_damage(attacker_id: int, victim_id: int, amount: float)

# UI events
signal show_damage_number(position: Vector3, amount: float, is_crit: bool)
signal show_notification(text: String, type: String)
signal ui_mode_changed(mode: String)
