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
signal upgrade_changed()

# --- Swamp Definitions ---
var swamp_definitions: Array = [
	{"name": "Puddle", "total_gallons": 0.5, "money_per_gallon": 50.0, "reward": 15.0},
	{"name": "Pond", "total_gallons": 10.0, "money_per_gallon": 50.0, "reward": 150.0},
	{"name": "Marsh", "total_gallons": 100.0, "money_per_gallon": 75.0, "reward": 2500.0},
	{"name": "Bog", "total_gallons": 800.0, "money_per_gallon": 125.0, "reward": 15000.0},
	{"name": "Deep Swamp", "total_gallons": 5000.0, "money_per_gallon": 200.0, "reward": 100000.0}
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
		"base_output": 0.3,
		"cost": 3000.0,
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
		"base_cost": 5.0,
		"cost_exponent": 1.12,
		"format": "gal"
	},
	"movement_speed": {
		"name": "Movement Speed",
		"base_value": 1.0,
		"per_level": 0.1,
		"base_cost": 8.0,
		"cost_exponent": 1.12,
		"format": "multiplier"
	},
	"stamina": {
		"name": "Stamina",
		"base_value": 5.0,
		"per_level": 3.0,
		"base_cost": 5.0,
		"cost_exponent": 1.12,
		"format": "value"
	},
	"stamina_regen": {
		"name": "Stamina Regen",
		"base_value": 0.8,
		"per_level": 0.5,
		"base_cost": 8.0,
		"cost_exponent": 1.12,
		"format": "per_sec"
	},
	# --- Global Power Stats (slightly pricier, scales faster) ---
	"water_value": {
		"name": "Water Value",
		"base_value": 1.0,
		"growth_rate": 1.08,
		"scale": "exponential",
		"base_cost": 50.0,
		"cost_exponent": 1.35,
		"format": "multiplier"
	},
	"scoop_power": {
		"name": "Scoop Power",
		"base_value": 1.0,
		"growth_rate": 1.10,
		"scale": "exponential",
		"base_cost": 35.0,
		"cost_exponent": 1.3,
		"format": "multiplier"
	},
	"drain_mastery": {
		"name": "Drain Mastery",
		"base_value": 0.0,
		"per_level": 0.05,
		"base_cost": 50.0,
		"cost_exponent": 1.35,
		"format": "percent",
		"max_value": 0.5
	}
}

# --- Pump Definition ---
const PUMP_COST: float = 100.0
const PUMP_BASE_DRAIN: float = 0.001  # gal/sec
const PUMP_DRAIN_PER_LEVEL: float = 0.0005  # additional gal/sec per level
const PUMP_UPGRADE_BASE: float = 50.0
const PUMP_SWAMP_EFFICIENCY: Array = [1.0, 0.5, 0.25, 0.1, 0.05]

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
const HOSE_DURATION: float = 30.0

# Pump state
var pump_owned: bool = false
var pump_level: int = 0

# Camel constants
const CAMEL_BASE_COST: float = 500.0
const CAMEL_COST_EXPONENT: float = 2.5
const CAMEL_BASE_CAPACITY: float = 1.0
const CAMEL_CAPACITY_PER_LEVEL: float = 0.5
const CAMEL_BASE_SPEED: float = 35.0
const CAMEL_SPEED_PER_LEVEL: float = 5.0
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
		"cost_exponent": 1.35,
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
		"cost_exponent": 1.4,
		"max_level": -1,
		"order": 3
	},
	"auto_scooper": {
		"name": "Auto-Scooper",
		"description": "Auto scoop near water",
		"cost": 500.0,
		"cost_exponent": 1.8,
		"max_level": -1,
		"order": 4
	}
}

# Upgrade state
var upgrades_owned: Dictionary = {
	"rain_collector": 0,
	"splash_guard": 0,
	"auto_seller": 0,
	"lucky_charm": 0,
	"auto_scooper": 0
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
	var raw: float = base * (1.0 + level * 0.2)
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
	var base: float = maxf(2.0 - get_stat_value("drain_mastery"), 0.5)
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
	return PUMP_BASE_DRAIN + PUMP_DRAIN_PER_LEVEL * pump_level

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
	return PUMP_UPGRADE_BASE * pow(1.15, pump_level)

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

	if swamp_states[swamp_index]["gallons_drained"] >= total and not swamp_states[swamp_index]["completed"]:
		swamp_states[swamp_index]["completed"] = true
		var reward: float = swamp_definitions[swamp_index]["reward"]
		money += reward
		money_changed.emit(money)
		swamp_completed.emit(swamp_index, reward)

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
		current_stamina = minf(current_stamina + 3.0, get_max_stamina())
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
	return CAMEL_BASE_CAPACITY + CAMEL_CAPACITY_PER_LEVEL * camel_capacity_level

func get_camel_speed() -> float:
	return CAMEL_BASE_SPEED + CAMEL_SPEED_PER_LEVEL * camel_speed_level

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
	return 0.50 + 0.30 * (level - 1)

func get_splash_guard_multiplier() -> float:
	var level: int = upgrades_owned["splash_guard"]
	if level <= 0:
		return 1.0
	return pow(0.85, 1) * pow(0.95, level - 1)

func get_lucky_charm_chance() -> float:
	var level: int = upgrades_owned["lucky_charm"]
	if level <= 0:
		return 0.0
	return 0.05 + 0.03 * (level - 1)

func has_auto_seller() -> bool:
	return upgrades_owned["auto_seller"] > 0

func get_auto_scoop_interval() -> float:
	var level: int = upgrades_owned["auto_scooper"]
	# Always active: base 2.5s, each upgrade level reduces by ~12%, min 0.1s
	return maxf(2.5 * pow(0.88, level), 0.1)

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
		"auto_scooper": 0
	}
	current_day = 1
	cycle_progress = 0.2
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
	# Hose auto-drain (earns money directly)
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
					var gallons: float = get_tool_output("hose") * delta
					drain_water(hose_swamp_index, gallons)
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
		"version": 9,
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
		"upgrades_owned": upgrades_owned.duplicate(true)
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
