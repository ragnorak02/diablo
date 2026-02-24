class_name PvPManager
extends Node
## Manages PvP interactions. Friendly fire is always enabled.
## Tracks PvP kills, handles death penalties and rewards.

var pvp_kill_bonus_xp: int = 50
var pvp_kill_gold_steal_pct: float = 0.1  # Steal 10% of victim's gold

var _kill_feed: Array[Dictionary] = []


func _ready() -> void:
	EventBus.pvp_damage.connect(_on_pvp_damage)
	EventBus.pvp_kill.connect(_on_pvp_kill)
	EventBus.player_died.connect(_on_player_died)


func _on_pvp_damage(attacker_id: int, victim_id: int, amount: float) -> void:
	GameManager.run_stats.damage_dealt += amount
	EventBus.show_notification.emit("PvP Hit! %.0f damage" % amount, "warning")


func _on_player_died(player_id: int) -> void:
	# Check if killed by another player (last damage source)
	# In single-player mode this is mostly for future multiplayer
	pass


func _on_pvp_kill(killer_id: int, victim_id: int) -> void:
	# Reward the killer
	GameManager.add_xp(pvp_kill_bonus_xp)
	var stolen_gold := int(GameManager.player_data.gold * pvp_kill_gold_steal_pct)
	GameManager.player_data.gold += stolen_gold

	_kill_feed.append({
		"killer": killer_id,
		"victim": victim_id,
		"time": GameManager.run_timer,
	})

	EventBus.show_notification.emit("PvP KILL! +%d XP, +%d Gold" % [pvp_kill_bonus_xp, stolen_gold], "warning")
