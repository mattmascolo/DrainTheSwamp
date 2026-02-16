extends Node

# --- Signals ---
signal money_changed(new_amount: float)
signal water_level_changed(swamp_index: int, new_percent: float)
signal tool_changed(tool_data: Dictionary)
signal tool_upgraded(tool_id: String, new_level: int)
signal stat_upgraded(stat_id: String, new_level: int)
signal stamina_changed(current: float, maximum: float)
signal scoop_performed(swamp_index: int, gallons: float, money_earned: float)
signal hose_state_changed(active: bool, time_remaining: float)
signal swamp_completed(swamp_index: int, reward: float)
signal pump_changed()
signal water_carried_changed(current: float, capacity: float)
signal day_changed(day: int)
signal camel_changed()
signal upgrade_changed
signal cave_unlocked(cave_id: String)
signal cave_entered(cave_id: String)
signal cave_exited(cave_id: String)
signal loot_collected(cave_id: String, loot_id: String, reward_text: String)
signal lore_read(cave_id: String, lore_id: String)

# --- Swamp Definitions ---
var swamp_definitions: Array = [
	{"name": "Puddle", "total_gallons": 5.0, "money_per_gallon": 25.0, "reward": 0.0},
	{"name": "Pond", "total_gallons": 25.0, "money_per_gallon": 50.0, "reward": 0.0},
	{"name": "Marsh", "total_gallons": 200.0, "money_per_gallon": 100.0, "reward": 0.0},
	{"name": "Bog", "total_gallons": 1500.0, "money_per_gallon": 300.0, "reward": 0.0},
	{"name": "Deep Swamp", "total_gallons": 8000.0, "money_per_gallon": 800.0, "reward": 0.0}
]

var swamp_states: Array = []

# --- Tool Definitions ---
var tool_definitions: Dictionary = {
	"hands": {
		"name": "Hands",
		"base_output": 0.015,
		"cost": 0.0,
		"type": "manual",
		"order": 0
	},
	"spoon": {
		"name": "Spoon",
		"base_output": 0.02,
		"cost": 15.0,
		"type": "manual",
		"order": 1
	},
	"cup": {
		"name": "Cup",
		"base_output": 0.1,
		"cost": 200.0,
		"type": "manual",
		"order": 2
	},
	"bucket": {
		"name": "Bucket",
		"base_output": 0.5,
		"cost": 2000.0,
		"type": "manual",
		"order": 3
	},
	"shovel": {
		"name": "Shovel",
		"base_output": 2.5,
		"cost": 15000.0,
		"type": "manual",
		"order": 4
	},
	"wheelbarrow": {
		"name": "Wheelbarrow",
		"base_output": 12.0,
		"cost": 75000.0,
		"type": "manual",
		"order": 5
	},
	"barrel": {
		"name": "Barrel",
		"base_output": 50.0,
		"cost": 400000.0,
		"type": "manual",
		"order": 6
	},
	"water_wagon": {
		"name": "Water Wagon",
		"base_output": 250.0,
		"cost": 2500000.0,
		"type": "manual",
		"order": 7
	},
	"hose": {
		"name": "Garden Hose",
		"base_output": 0.5,
		"cost": 8000.0,
		"type": "semi_auto",
		"order": 8
	}
}

# --- Stat Definitions ---
var stat_definitions: Dictionary = {
	# --- Core Stats (cheap, QoL) ---
	"carrying_capacity": {
		"name": "Carrying Capacity",
		"base_value": 1.0,
		"growth_rate": 1.18,
		"scale": "exponential",
		"base_cost": 10.0,
		"cost_exponent": 1.20,
		"format": "gal"
	},
	"movement_speed": {
		"name": "Movement Speed",
		"base_value": 1.0,
		"growth_rate": 1.12,
		"scale": "exponential",
		"base_cost": 12.0,
		"cost_exponent": 1.14,
		"format": "multiplier"
	},
	"stamina": {
		"name": "Stamina",
		"base_value": 5.0,
		"growth_rate": 1.15,
		"scale": "exponential",
		"base_cost": 10.0,
		"cost_exponent": 1.18,
		"format": "value"
	},
	"stamina_regen": {
		"name": "Stamina Regen",
		"base_value": 0.8,
		"growth_rate": 1.15,
		"scale": "exponential",
		"base_cost": 12.0,
		"cost_exponent": 1.18,
		"format": "per_sec"
	},
	# --- Global Power Stats (slightly pricier, scales faster) ---
	"water_value": {
		"name": "Water Value",
		"base_value": 1.0,
		"growth_rate": 1.30,
		"scale": "exponential",
		"base_cost": 50.0,
		"cost_exponent": 1.30,
		"format": "multiplier"
	},
	"scoop_power": {
		"name": "Scoop Power",
		"base_value": 1.0,
		"growth_rate": 1.28,
		"scale": "exponential",
		"base_cost": 35.0,
		"cost_exponent": 1.28,
		"format": "multiplier"
	},
	"drain_mastery": {
		"name": "Drain Mastery",
		"base_value": 1.0,
		"growth_rate": 1.30,
		"scale": "exponential",
		"base_cost": 50.0,
		"cost_exponent": 1.30,
		"format": "multiplier"
	}
}

# --- Pump Definition ---
const PUMP_COST: float = 500.0
const PUMP_UPGRADE_BASE: float = 100.0
const PUMP_SWAMP_EFFICIENCY: Array = [1.0, 0.8, 0.6, 0.4, 0.25]

# --- Game State ---
var money: float = 0.0
var current_tool_id: String = "hands"

var tools_owned: Dictionary = {
	"hands": {"owned": true, "level": 0},
	"spoon": {"owned": false, "level": 0},
	"cup": {"owned": false, "level": 0},
	"bucket": {"owned": false, "level": 0},
	"shovel": {"owned": false, "level": 0},
	"wheelbarrow": {"owned": false, "level": 0},
	"barrel": {"owned": false, "level": 0},
	"water_wagon": {"owned": false, "level": 0},
	"hose": {"owned": false, "level": 0}
}

var stat_levels: Dictionary = {
	"carrying_capacity": 0,
	"movement_speed": 0,
	"stamina": 0,
	"stamina_regen": 0,
	"water_value": 0,
	"scoop_power": 0,
	"drain_mastery": 0
}

var current_stamina: float = 5.0

# Carrying water inventory
var water_carried: float = 0.0
var last_scoop_swamp: int = 0

# Hose state
var hose_active: bool = false
var hose_timer: float = 0.0
var hose_swamp_index: int = -1
const HOSE_DURATION: float = 20.0

# Pump state
var pump_owned: bool = false
var pump_level: int = 0

# Camel constants
const CAMEL_BASE_COST: float = 500.0
const CAMEL_COST_EXPONENT: float = 1.8
const CAMEL_CAPACITY_UPGRADE_BASE: float = 50.0
const CAMEL_SPEED_UPGRADE_BASE: float = 75.0
const CAMEL_UPGRADE_EXPONENT: float = 1.25

# Camel state
var camel_count: int = 0
var camel_capacity_level: int = 0
var camel_speed_level: int = 0
var camel_states: Array = []  # [{state, x, water_carried, source_swamp, state_timer}]

# Upgrade definitions
var upgrade_definitions: Dictionary = {
	"rain_collector": {
		"name": "Rain Collector",
		"description": "Passive income",
		"cost": 5000.0,
		"cost_exponent": 1.3,
		"max_level": -1,
		"order": 0
	},
	"splash_guard": {
		"name": "Splash Guard",
		"description": "Stamina efficiency",
		"cost": 2000.0,
		"cost_exponent": 1.20,
		"max_level": -1,
		"order": 1
	},
	"auto_seller": {
		"name": "Auto-Seller",
		"description": "Auto-sell when full",
		"cost": 10000.0,
		"cost_exponent": 1.0,
		"max_level": 1,
		"order": 2
	},
	"lucky_charm": {
		"name": "Lucky Charm",
		"description": "Bonus money chance",
		"cost": 3000.0,
		"cost_exponent": 1.35,
		"max_level": -1,
		"order": 3
	},
	"auto_scooper": {
		"name": "Auto-Scooper",
		"description": "Auto scoop near water",
		"cost": 500.0,
		"cost_exponent": 1.25,
		"max_level": -1,
		"order": 4
	},
	"lantern": {
		"name": "Lantern",
		"description": "Light in the dark",
		"cost": 50.0,
		"cost_exponent": 1.40,
		"max_level": -1,
		"order": 5
	}
}

# Upgrade state
var upgrades_owned: Dictionary = {
	"rain_collector": 0,
	"splash_guard": 0,
	"auto_seller": 0,
	"lucky_charm": 0,
	"auto_scooper": 0,
	"lantern": 0
}

# --- Cave Definitions ---
const CAVE_DEFINITIONS: Dictionary = {
	"muddy_hollow": {"name": "Muddy Hollow", "swamp_index": 0, "drain_threshold": 0.0, "scene_path": "res://scenes/caves/muddy_hollow.tscn", "order": 0},
	"gator_den": {"name": "Gator Den", "swamp_index": 1, "drain_threshold": 0.0, "scene_path": "res://scenes/caves/gator_den.tscn", "order": 1},
	"the_sinkhole": {"name": "The Sinkhole", "swamp_index": 2, "drain_threshold": 0.0, "scene_path": "res://scenes/caves/the_sinkhole.tscn", "order": 2},
	"collapsed_mine": {"name": "Collapsed Mine", "swamp_index": 3, "drain_threshold": 0.0, "scene_path": "res://scenes/caves/collapsed_mine.tscn", "order": 3},
	"the_abyss": {"name": "The Abyss", "swamp_index": 4, "drain_threshold": 0.0, "scene_path": "res://scenes/caves/the_abyss.tscn", "order": 4},
}

# Cave state
var in_cave: bool = false
var current_cave: String = ""
var cave_data: Dictionary = {
	"muddy_hollow": {"unlocked": false, "entered": false, "loot_collected": {}},
	"gator_den": {"unlocked": false, "entered": false, "loot_collected": {}},
	"the_sinkhole": {"unlocked": false, "entered": false, "loot_collected": {}},
	"collapsed_mine": {"unlocked": false, "entered": false, "loot_collected": {}},
	"the_abyss": {"unlocked": false, "entered": false, "loot_collected": {}},
}

# Day tracking
var current_day: int = 1
var cycle_progress: float = 0.2

func _ready() -> void:
	_init_swamp_states()

func _init_swamp_states() -> void:
	swamp_states.clear()
	for i in range(swamp_definitions.size()):
		swamp_states.append({"gallons_drained": 0.0, "completed": false})

# --- Computed Properties ---
func get_swamp_count() -> int:
	return swamp_definitions.size()

func get_swamp_water_percent(swamp_index: int) -> float:
	var total: float = swamp_definitions[swamp_index]["total_gallons"]
	var drained: float = swamp_states[swamp_index]["gallons_drained"]
	return clampf((total - drained) / total * 100.0, 0.0, 100.0)

func get_swamp_fill_fraction(swamp_index: int) -> float:
	var total: float = swamp_definitions[swamp_index]["total_gallons"]
	var drained: float = swamp_states[swamp_index]["gallons_drained"]
	return clampf((total - drained) / total, 0.0, 1.0)

func is_swamp_completed(swamp_index: int) -> bool:
	return swamp_states[swamp_index]["completed"]

func get_total_water_percent() -> float:
	var total_gal: float = 0.0
	var total_drained: float = 0.0
	for i in range(swamp_definitions.size()):
		total_gal += swamp_definitions[i]["total_gallons"]
		total_drained += swamp_states[i]["gallons_drained"]
	if total_gal == 0.0:
		return 0.0
	return clampf((total_gal - total_drained) / total_gal * 100.0, 0.0, 100.0)

func get_tool_output(tool_id: String) -> float:
	var base: float = tool_definitions[tool_id]["base_output"]
	var level: int = tools_owned[tool_id]["level"]
	var raw: float = base * pow(1.30, level)
	# Apply scoop power multiplier for manual tools
	if tool_definitions[tool_id]["type"] == "manual":
		raw *= get_stat_value("scoop_power")
	return raw

func get_effective_scoop(tool_id: String) -> float:
	return get_tool_output(tool_id)

func get_stat_value(stat_id: String) -> float:
	var defn: Dictionary = stat_definitions[stat_id]
	var value: float
	if defn.get("scale", "linear") == "exponential":
		value = defn["base_value"] * pow(defn["growth_rate"], stat_levels[stat_id])
	else:
		value = defn["base_value"] + defn["per_level"] * stat_levels[stat_id]
	if defn.has("max_value"):
		value = minf(value, defn["max_value"])
	return value

func get_stat_value_at_level(stat_id: String, level: int) -> float:
	var defn: Dictionary = stat_definitions[stat_id]
	var value: float
	if defn.get("scale", "linear") == "exponential":
		value = defn["base_value"] * pow(defn["growth_rate"], level)
	else:
		value = defn["base_value"] + defn["per_level"] * level
	if defn.has("max_value"):
		value = minf(value, defn["max_value"])
	return value

func get_money_multiplier() -> float:
	return get_stat_value("water_value")

func get_stamina_cost() -> float:
	var base: float = maxf(2.0 / get_stat_value("drain_mastery"), 0.2)
	return base * get_splash_guard_multiplier()

func get_max_stamina() -> float:
	return get_stat_value("stamina")

func get_stamina_regen_rate() -> float:
	return get_stat_value("stamina_regen")

func get_movement_speed_multiplier() -> float:
	return get_stat_value("movement_speed")

func get_tool_upgrade_cost(tool_id: String) -> float:
	var base_cost: float = tool_definitions[tool_id]["cost"]
	if base_cost == 0.0:
		base_cost = 10.0
	var level: int = tools_owned[tool_id]["level"]
	return base_cost * pow(1.3, level)

func get_stat_upgrade_cost(stat_id: String) -> float:
	var defn: Dictionary = stat_definitions[stat_id]
	var base_cost: float = defn["base_cost"]
	var exponent: float = defn.get("cost_exponent", 1.15)
	var level: int = stat_levels[stat_id]
	return base_cost * pow(exponent, level)

# --- Pump computed ---
func get_pump_drain_rate() -> float:
	return 0.005 * pow(1.20, pump_level)

func get_pump_income_rate() -> float:
	var total_income: float = 0.0
	var base_rate: float = get_pump_drain_rate()
	for i in range(swamp_definitions.size()):
		if swamp_states[i]["completed"]:
			continue
		var eff: float = PUMP_SWAMP_EFFICIENCY[i] if i < PUMP_SWAMP_EFFICIENCY.size() else 0.05
		total_income += base_rate * eff * swamp_definitions[i]["money_per_gallon"] * get_money_multiplier()
	return total_income

func get_pump_upgrade_cost() -> float:
	return PUMP_UPGRADE_BASE * pow(1.20, pump_level)

# --- Internal: drain swamp without earning money ---
func _drain_swamp(swamp_index: int, gallons: float) -> float:
	if gallons <= 0.0 or swamp_index < 0 or swamp_index >= swamp_definitions.size():
		return 0.0
	if swamp_states[swamp_index]["completed"]:
		return 0.0
	var total: float = swamp_definitions[swamp_index]["total_gallons"]
	var remaining: float = total - swamp_states[swamp_index]["gallons_drained"]
	var actual: float = minf(gallons, remaining)
	if actual <= 0.0:
		return 0.0
	swamp_states[swamp_index]["gallons_drained"] += actual
	water_level_changed.emit(swamp_index, get_swamp_water_percent(swamp_index))
	check_cave_unlocks(swamp_index)

	if swamp_states[swamp_index]["gallons_drained"] >= total and not swamp_states[swamp_index]["completed"]:
		swamp_states[swamp_index]["completed"] = true
		swamp_completed.emit(swamp_index, 0.0)

	return actual

# --- Actions ---
# drain_water: used by hose and pump (earns money directly)
func drain_water(swamp_index: int, gallons: float) -> void:
	var actual: float = _drain_swamp(swamp_index, gallons)
	if actual > 0.0:
		var mpg: float = swamp_definitions[swamp_index]["money_per_gallon"] * get_money_multiplier()
		var earned: float = actual * mpg
		money += earned
		money_changed.emit(money)
		scoop_performed.emit(swamp_index, actual, earned)

# try_scoop: manual scooping fills player inventory (no instant money)
func try_scoop(swamp_index: int) -> bool:
	var stamina_cost: float = get_stamina_cost()
	if current_stamina < stamina_cost:
		return false
	if swamp_index < 0 or swamp_index >= swamp_definitions.size():
		return false
	if swamp_states[swamp_index]["completed"]:
		return false
	if tool_definitions[current_tool_id]["type"] == "semi_auto":
		return false

	var capacity: float = get_stat_value("carrying_capacity")
	var remaining_space: float = capacity - water_carried
	if remaining_space <= 0.001:
		return false

	var tool_output: float = get_tool_output(current_tool_id)
	var scoop_amount: float = minf(tool_output, remaining_space)

	current_stamina -= stamina_cost
	stamina_changed.emit(current_stamina, get_max_stamina())

	var actual: float = _drain_swamp(swamp_index, scoop_amount)
	if actual > 0.0:
		water_carried += actual
		last_scoop_swamp = swamp_index
		water_carried_changed.emit(water_carried, capacity)
		scoop_performed.emit(swamp_index, actual, 0.0)
	return actual > 0.0

# sell_water: convert carried water to money (at sell point)
func sell_water() -> float:
	if water_carried <= 0.0001:
		return 0.0
	var base_mpg: float = swamp_definitions[last_scoop_swamp]["money_per_gallon"]
	var mpg: float = base_mpg * get_money_multiplier()
	var earned: float = water_carried * mpg
	# Lucky Charm: chance for 2x money on sale
	if get_lucky_charm_chance() > 0.0 and randf() < get_lucky_charm_chance():
		earned *= 2.0
	money += earned
	water_carried = 0.0
	money_changed.emit(money)
	water_carried_changed.emit(0.0, get_stat_value("carrying_capacity"))
	return earned

func is_inventory_full() -> bool:
	var capacity: float = get_stat_value("carrying_capacity")
	return water_carried >= capacity - 0.0001

func try_activate_hose(swamp_index: int) -> bool:
	if current_tool_id != "hose":
		return false
	if not tools_owned["hose"]["owned"]:
		return false
	if hose_active:
		return false
	if swamp_index < 0 or swamp_index >= swamp_definitions.size():
		return false
	if swamp_states[swamp_index]["completed"]:
		return false
	hose_active = true
	hose_timer = HOSE_DURATION
	hose_swamp_index = swamp_index
	hose_state_changed.emit(true, hose_timer)
	return true

func buy_tool(tool_id: String) -> bool:
	if tools_owned[tool_id]["owned"]:
		return false
	var cost: float = tool_definitions[tool_id]["cost"]
	if money < cost:
		return false
	money -= cost
	tools_owned[tool_id]["owned"] = true
	money_changed.emit(money)
	return true

func equip_tool(tool_id: String) -> void:
	if tools_owned[tool_id]["owned"]:
		current_tool_id = tool_id
		tool_changed.emit(tool_definitions[tool_id])

func upgrade_tool(tool_id: String) -> bool:
	if not tools_owned[tool_id]["owned"]:
		return false
	var cost: float = get_tool_upgrade_cost(tool_id)
	if money < cost:
		return false
	money -= cost
	tools_owned[tool_id]["level"] += 1
	money_changed.emit(money)
	tool_upgraded.emit(tool_id, tools_owned[tool_id]["level"])
	return true

func upgrade_stat(stat_id: String) -> bool:
	var cost: float = get_stat_upgrade_cost(stat_id)
	if money < cost:
		return false
	money -= cost
	stat_levels[stat_id] += 1
	money_changed.emit(money)
	stat_upgraded.emit(stat_id, stat_levels[stat_id])
	if stat_id == "stamina":
		current_stamina = get_max_stamina()
		stamina_changed.emit(current_stamina, get_max_stamina())
	return true

func buy_pump() -> bool:
	if pump_owned:
		return false
	if money < PUMP_COST:
		return false
	money -= PUMP_COST
	pump_owned = true
	money_changed.emit(money)
	pump_changed.emit()
	return true

func upgrade_pump() -> bool:
	if not pump_owned:
		return false
	var cost: float = get_pump_upgrade_cost()
	if money < cost:
		return false
	money -= cost
	pump_level += 1
	money_changed.emit(money)
	pump_changed.emit()
	return true

# --- Camel computed ---
func get_camel_cost() -> float:
	return CAMEL_BASE_COST * pow(CAMEL_COST_EXPONENT, camel_count)

func get_camel_capacity() -> float:
	return 1.0 * pow(1.25, camel_capacity_level)

func get_camel_speed() -> float:
	return 35.0 * pow(1.20, camel_speed_level)

func get_camel_capacity_upgrade_cost() -> float:
	return CAMEL_CAPACITY_UPGRADE_BASE * pow(CAMEL_UPGRADE_EXPONENT, camel_capacity_level)

func get_camel_speed_upgrade_cost() -> float:
	return CAMEL_SPEED_UPGRADE_BASE * pow(CAMEL_UPGRADE_EXPONENT, camel_speed_level)

# --- Upgrade computed ---
func get_upgrade_cost(upgrade_id: String) -> float:
	var defn: Dictionary = upgrade_definitions[upgrade_id]
	var level: int = upgrades_owned[upgrade_id]
	return defn["cost"] * pow(defn["cost_exponent"], level)

func get_rain_collector_rate() -> float:
	var level: int = upgrades_owned["rain_collector"]
	if level <= 0:
		return 0.0
	return 0.50 * pow(1.30, level - 1)

func get_splash_guard_multiplier() -> float:
	var level: int = upgrades_owned["splash_guard"]
	if level <= 0:
		return 1.0
	return pow(0.82, level)

func get_lucky_charm_chance() -> float:
	var level: int = upgrades_owned["lucky_charm"]
	if level <= 0:
		return 0.0
	return minf(0.05 * pow(1.35, level - 1), 0.80)

func has_auto_seller() -> bool:
	return upgrades_owned["auto_seller"] > 0

func get_auto_scoop_interval() -> float:
	var level: int = upgrades_owned["auto_scooper"]
	# Always active: base 2.5s, each upgrade level reduces by ~12%, min 0.1s
	return maxf(2.5 * pow(0.88, level), 0.1)

func get_lantern_radius() -> float:
	var level: int = upgrades_owned["lantern"]
	if level <= 0:
		return 0.0
	return 48.0 * pow(1.40, level - 1)

func get_lantern_energy() -> float:
	var level: int = upgrades_owned["lantern"]
	if level <= 0:
		return 0.0
	return minf(2.4 * pow(1.12, level - 1), 8.0)

func get_darkness_factor() -> float:
	if in_cave:
		return 1.0
	var t: float = cycle_progress
	# Mirror _get_cycle_color breakpoints: full day 0.22-0.55, full night 0.75-1.0/0.0-0.1
	# Darkness = how far from noon brightness (1.0 = full night, 0.0 = full day)
	if t < 0.1:
		return 1.0
	elif t < 0.22:
		return lerpf(1.0, 0.0, (t - 0.1) / 0.12)
	elif t < 0.55:
		return 0.0
	elif t < 0.68:
		return lerpf(0.0, 1.0, (t - 0.55) / 0.13)
	else:
		return 1.0

func is_upgrade_maxed(upgrade_id: String) -> bool:
	var defn: Dictionary = upgrade_definitions[upgrade_id]
	if defn["max_level"] < 0:
		return false
	return upgrades_owned[upgrade_id] >= defn["max_level"]

# --- Upgrade actions ---
func buy_upgrade(upgrade_id: String) -> bool:
	if is_upgrade_maxed(upgrade_id):
		return false
	var cost: float = get_upgrade_cost(upgrade_id)
	if money < cost:
		return false
	money -= cost
	upgrades_owned[upgrade_id] += 1
	money_changed.emit(money)
	upgrade_changed.emit()
	return true

# --- Camel actions ---
func buy_camel() -> bool:
	var cost: float = get_camel_cost()
	if money < cost:
		return false
	money -= cost
	camel_count += 1
	camel_states.append({"state": "to_player", "x": 30.0, "water_carried": 0.0, "source_swamp": 0, "state_timer": 0.0})
	money_changed.emit(money)
	camel_changed.emit()
	return true

func upgrade_camel_capacity() -> bool:
	if camel_count <= 0:
		return false
	var cost: float = get_camel_capacity_upgrade_cost()
	if money < cost:
		return false
	money -= cost
	camel_capacity_level += 1
	money_changed.emit(money)
	camel_changed.emit()
	return true

func upgrade_camel_speed() -> bool:
	if camel_count <= 0:
		return false
	var cost: float = get_camel_speed_upgrade_cost()
	if money < cost:
		return false
	money -= cost
	camel_speed_level += 1
	money_changed.emit(money)
	camel_changed.emit()
	return true

func camel_take_water(index: int) -> void:
	if index < 0 or index >= camel_states.size():
		return
	var capacity: float = get_camel_capacity()
	var take_amount: float = minf(water_carried, capacity)
	if take_amount <= 0.0001:
		return
	camel_states[index]["water_carried"] = take_amount
	camel_states[index]["source_swamp"] = last_scoop_swamp
	water_carried -= take_amount
	water_carried_changed.emit(water_carried, get_stat_value("carrying_capacity"))

func camel_sell_water(index: int) -> float:
	if index < 0 or index >= camel_states.size():
		return 0.0
	var carried: float = camel_states[index]["water_carried"]
	if carried <= 0.0001:
		return 0.0
	var swamp_idx: int = camel_states[index]["source_swamp"]
	var base_mpg: float = swamp_definitions[swamp_idx]["money_per_gallon"]
	var mpg: float = base_mpg * get_money_multiplier()
	var earned: float = carried * mpg
	money += earned
	camel_states[index]["water_carried"] = 0.0
	money_changed.emit(money)
	return earned

func _init_camel_states() -> void:
	camel_states.clear()
	for i in range(camel_count):
		camel_states.append({"state": "to_player", "x": 30.0, "water_carried": 0.0, "source_swamp": 0, "state_timer": 0.0})

# --- Cave Functions ---
func check_cave_unlocks(swamp_index: int = -1) -> void:
	for cave_id: String in CAVE_DEFINITIONS:
		var defn: Dictionary = CAVE_DEFINITIONS[cave_id]
		if cave_data[cave_id]["unlocked"]:
			continue
		var si: int = defn["swamp_index"]
		if swamp_index >= 0 and si != swamp_index:
			continue
		var fill: float = get_swamp_fill_fraction(si)
		if fill <= defn["drain_threshold"]:
			cave_data[cave_id]["unlocked"] = true
			cave_unlocked.emit(cave_id)

func is_cave_unlocked(cave_id: String) -> bool:
	return cave_data.get(cave_id, {}).get("unlocked", false)

func enter_cave(cave_id: String) -> void:
	in_cave = true
	current_cave = cave_id
	cave_data[cave_id]["entered"] = true
	cave_entered.emit(cave_id)

func exit_cave() -> void:
	var old_cave: String = current_cave
	in_cave = false
	current_cave = ""
	cave_exited.emit(old_cave)

func collect_loot(cave_id: String, loot_id: String, reward_text: String) -> void:
	if not cave_data.has(cave_id):
		return
	cave_data[cave_id]["loot_collected"][loot_id] = true
	loot_collected.emit(cave_id, loot_id, reward_text)

func is_loot_collected(cave_id: String, loot_id: String) -> bool:
	if not cave_data.has(cave_id):
		return false
	return cave_data[cave_id]["loot_collected"].get(loot_id, false)

func reset_game() -> void:
	money = 0.0
	current_tool_id = "hands"
	tools_owned = {
		"hands": {"owned": true, "level": 0},
		"spoon": {"owned": false, "level": 0},
		"cup": {"owned": false, "level": 0},
		"bucket": {"owned": false, "level": 0},
		"shovel": {"owned": false, "level": 0},
		"wheelbarrow": {"owned": false, "level": 0},
		"barrel": {"owned": false, "level": 0},
		"water_wagon": {"owned": false, "level": 0},
		"hose": {"owned": false, "level": 0}
	}
	stat_levels = {
		"carrying_capacity": 0,
		"movement_speed": 0,
		"stamina": 0,
		"stamina_regen": 0,
		"water_value": 0,
		"scoop_power": 0,
		"drain_mastery": 0
	}
	current_stamina = get_max_stamina()
	water_carried = 0.0
	last_scoop_swamp = 0
	hose_active = false
	hose_timer = 0.0
	hose_swamp_index = -1
	pump_owned = false
	pump_level = 0
	camel_count = 0
	camel_capacity_level = 0
	camel_speed_level = 0
	camel_states.clear()
	upgrades_owned = {
		"rain_collector": 0,
		"splash_guard": 0,
		"auto_seller": 0,
		"lucky_charm": 0,
		"auto_scooper": 0,
		"lantern": 0
	}
	current_day = 1
	cycle_progress = 0.2
	in_cave = false
	current_cave = ""
	cave_data = {
		"muddy_hollow": {"unlocked": false, "entered": false, "loot_collected": {}},
		"gator_den": {"unlocked": false, "entered": false, "loot_collected": {}},
		"the_sinkhole": {"unlocked": false, "entered": false, "loot_collected": {}},
		"collapsed_mine": {"unlocked": false, "entered": false, "loot_collected": {}},
		"the_abyss": {"unlocked": false, "entered": false, "loot_collected": {}},
	}
	_init_swamp_states()

	# Emit all signals to update UI
	money_changed.emit(money)
	for i in range(swamp_definitions.size()):
		water_level_changed.emit(i, get_swamp_water_percent(i))
	stamina_changed.emit(current_stamina, get_max_stamina())
	tool_changed.emit(tool_definitions[current_tool_id])
	hose_state_changed.emit(false, 0.0)
	pump_changed.emit()
	water_carried_changed.emit(0.0, get_stat_value("carrying_capacity"))
	camel_changed.emit()
	upgrade_changed.emit()
	day_changed.emit(current_day)

func regen_stamina(delta: float) -> void:
	var max_stam: float = get_max_stamina()
	if current_stamina < max_stam:
		var rate: float = get_stamina_regen_rate()
		current_stamina = minf(current_stamina + rate * delta, max_stam)
		stamina_changed.emit(current_stamina, max_stam)

func _process(delta: float) -> void:
	# Hose fills water_carried (like manual scooping, player must sell at shop)
	if hose_active:
		hose_timer -= delta
		if hose_timer <= 0.0:
			hose_active = false
			hose_timer = 0.0
			hose_swamp_index = -1
			hose_state_changed.emit(false, 0.0)
		else:
			if hose_swamp_index >= 0 and hose_swamp_index < swamp_definitions.size():
				if swamp_states[hose_swamp_index]["completed"]:
					hose_active = false
					hose_timer = 0.0
					hose_swamp_index = -1
					hose_state_changed.emit(false, 0.0)
				else:
					var capacity: float = get_stat_value("carrying_capacity")
					var remaining_space: float = capacity - water_carried
					if remaining_space <= 0.001:
						hose_active = false
						hose_timer = 0.0
						hose_swamp_index = -1
						hose_state_changed.emit(false, 0.0)
					else:
						var gallons: float = minf(get_tool_output("hose") * delta, remaining_space)
						var actual: float = _drain_swamp(hose_swamp_index, gallons)
						if actual > 0.0:
							water_carried += actual
							last_scoop_swamp = hose_swamp_index
							water_carried_changed.emit(water_carried, capacity)
						hose_state_changed.emit(true, hose_timer)

	# Pump passive drain (earns money directly, drains all pools)
	if pump_owned:
		var base_rate: float = get_pump_drain_rate()
		for i in range(swamp_definitions.size()):
			if swamp_states[i]["completed"]:
				continue
			var eff: float = PUMP_SWAMP_EFFICIENCY[i] if i < PUMP_SWAMP_EFFICIENCY.size() else 0.05
			var gallons: float = base_rate * eff * delta
			drain_water(i, gallons)

	# Rain Collector passive income
	var rain_rate: float = get_rain_collector_rate()
	if rain_rate > 0.0:
		money += rain_rate * delta
		money_changed.emit(money)

	# Auto-Seller: sell when inventory full
	if has_auto_seller() and is_inventory_full():
		sell_water()

func get_save_data() -> Dictionary:
	var swamp_save: Array = []
	for state in swamp_states:
		swamp_save.append({"gallons_drained": state["gallons_drained"], "completed": state["completed"]})
	return {
		"version": 12,
		"money": money,
		"current_tool_id": current_tool_id,
		"tools_owned": tools_owned.duplicate(true),
		"stat_levels": stat_levels.duplicate(true),
		"current_stamina": current_stamina,
		"water_carried": water_carried,
		"last_scoop_swamp": last_scoop_swamp,
		"swamp_states": swamp_save,
		"pump_owned": pump_owned,
		"pump_level": pump_level,
		"current_day": current_day,
		"camel_count": camel_count,
		"camel_capacity_level": camel_capacity_level,
		"camel_speed_level": camel_speed_level,
		"upgrades_owned": upgrades_owned.duplicate(true),
		"cave_data": cave_data.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	money = data.get("money", 0.0)
	current_tool_id = data.get("current_tool_id", "spoon")
	if data.has("tools_owned"):
		for key in data["tools_owned"]:
			var k: String = key
			if tools_owned.has(k):
				tools_owned[k] = data["tools_owned"][k]
	if data.has("stat_levels"):
		for key in data["stat_levels"]:
			var k: String = key
			if stat_levels.has(k):
				stat_levels[k] = data["stat_levels"][k]
	current_stamina = data.get("current_stamina", get_max_stamina())
	water_carried = data.get("water_carried", 0.0)
	last_scoop_swamp = int(data.get("last_scoop_swamp", 0))

	# Pump
	pump_owned = data.get("pump_owned", false)
	pump_level = data.get("pump_level", 0)
	current_day = int(data.get("current_day", 1))

	# Load swamp states
	if data.has("swamp_states"):
		var saved_swamps: Array = data["swamp_states"]
		for i in range(mini(saved_swamps.size(), swamp_states.size())):
			swamp_states[i]["gallons_drained"] = saved_swamps[i].get("gallons_drained", 0.0)
			swamp_states[i]["completed"] = saved_swamps[i].get("completed", false)
	elif data.has("gallons_drained"):
		var old_drained: float = data["gallons_drained"]
		swamp_states[0]["gallons_drained"] = minf(old_drained, swamp_definitions[0]["total_gallons"])
		if swamp_states[0]["gallons_drained"] >= swamp_definitions[0]["total_gallons"]:
			swamp_states[0]["completed"] = true

	# Camels
	camel_count = int(data.get("camel_count", 0))
	camel_capacity_level = int(data.get("camel_capacity_level", 0))
	camel_speed_level = int(data.get("camel_speed_level", 0))
	_init_camel_states()

	# Upgrades
	if data.has("upgrades_owned"):
		for key in data["upgrades_owned"]:
			var k: String = key
			if upgrades_owned.has(k):
				upgrades_owned[k] = int(data["upgrades_owned"][k])

	# Cave data
	if data.has("cave_data"):
		for key in data["cave_data"]:
			var k: String = key
			if cave_data.has(k):
				var saved: Dictionary = data["cave_data"][k]
				cave_data[k]["unlocked"] = saved.get("unlocked", false)
				cave_data[k]["entered"] = saved.get("entered", false)
				if saved.has("loot_collected"):
					cave_data[k]["loot_collected"] = saved["loot_collected"].duplicate()

	# Version migration
	var save_version: int = int(data.get("version", 1))
	if save_version < 12:
		# Swamp sizes changed in v12 — clamp drained to new caps
		for i in range(swamp_states.size()):
			var cap: float = swamp_definitions[i]["total_gallons"]
			swamp_states[i]["gallons_drained"] = minf(swamp_states[i]["gallons_drained"], cap)
			swamp_states[i]["completed"] = swamp_states[i]["gallons_drained"] >= cap

	# Emit signals
	money_changed.emit(money)
	for i in range(swamp_definitions.size()):
		water_level_changed.emit(i, get_swamp_water_percent(i))
	stamina_changed.emit(current_stamina, get_max_stamina())
	tool_changed.emit(tool_definitions[current_tool_id])
	pump_changed.emit()
	water_carried_changed.emit(water_carried, get_stat_value("carrying_capacity"))
	camel_changed.emit()
	upgrade_changed.emit()
