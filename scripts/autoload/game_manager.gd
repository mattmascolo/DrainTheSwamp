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

# --- Swamp Definitions ---
var swamp_definitions: Array = [
	{"name": "Puddle", "total_gallons": 0.5, "money_per_gallon": 50.0, "reward": 10.0},
	{"name": "Pond", "total_gallons": 10.0, "money_per_gallon": 50.0, "reward": 100.0},
	{"name": "Marsh", "total_gallons": 100.0, "money_per_gallon": 50.0, "reward": 1000.0},
	{"name": "Bog", "total_gallons": 800.0, "money_per_gallon": 50.0, "reward": 5000.0},
	{"name": "Deep Swamp", "total_gallons": 5000.0, "money_per_gallon": 50.0, "reward": 25000.0}
]

var swamp_states: Array = []

# --- Tool Definitions ---
var tool_definitions: Dictionary = {
	"hands": {
		"name": "Hands",
		"base_output": 0.001,
		"cost": 0.0,
		"type": "manual",
		"order": 0
	},
	"spoon": {
		"name": "Spoon",
		"base_output": 0.005,
		"cost": 15.0,
		"type": "manual",
		"order": 1
	},
	"cup": {
		"name": "Cup",
		"base_output": 0.025,
		"cost": 150.0,
		"type": "manual",
		"order": 2
	},
	"bucket": {
		"name": "Bucket",
		"base_output": 0.15,
		"cost": 1500.0,
		"type": "manual",
		"order": 3
	},
	"shovel": {
		"name": "Shovel",
		"base_output": 1.0,
		"cost": 10000.0,
		"type": "manual",
		"order": 4
	},
	"wheelbarrow": {
		"name": "Wheelbarrow",
		"base_output": 5.0,
		"cost": 50000.0,
		"type": "manual",
		"order": 5
	},
	"barrel": {
		"name": "Barrel",
		"base_output": 25.0,
		"cost": 250000.0,
		"type": "manual",
		"order": 6
	},
	"water_wagon": {
		"name": "Water Wagon",
		"base_output": 150.0,
		"cost": 1500000.0,
		"type": "manual",
		"order": 7
	},
	"hose": {
		"name": "Garden Hose",
		"base_output": 0.05,
		"cost": 5000.0,
		"type": "semi_auto",
		"order": 8
	}
}

# --- Stat Definitions ---
var stat_definitions: Dictionary = {
	"carrying_capacity": {
		"name": "Carrying Capacity",
		"base_value": 0.5,
		"per_level": 1.0,
		"base_cost": 10.0,
		"cost_exponent": 1.15,
		"format": "gal"
	},
	"movement_speed": {
		"name": "Movement Speed",
		"base_value": 1.0,
		"per_level": 0.1,
		"base_cost": 25.0,
		"cost_exponent": 1.3,
		"format": "multiplier"
	},
	"stamina": {
		"name": "Stamina",
		"base_value": 5.0,
		"per_level": 3.0,
		"base_cost": 15.0,
		"cost_exponent": 1.25,
		"format": "value"
	},
	"stamina_regen": {
		"name": "Stamina Regen",
		"base_value": 1.0,
		"per_level": 0.5,
		"base_cost": 20.0,
		"cost_exponent": 1.3,
		"format": "per_sec"
	},
	"water_value": {
		"name": "Water Value",
		"base_value": 1.0,
		"per_level": 0.1,
		"base_cost": 50.0,
		"cost_exponent": 1.5,
		"format": "multiplier"
	},
	"scoop_power": {
		"name": "Scoop Power",
		"base_value": 1.0,
		"per_level": 0.15,
		"base_cost": 75.0,
		"cost_exponent": 1.5,
		"format": "multiplier"
	},
	"lucky_scoop": {
		"name": "Lucky Scoop",
		"base_value": 0.0,
		"per_level": 0.05,
		"base_cost": 100.0,
		"cost_exponent": 1.6,
		"format": "percent"
	},
	"drain_mastery": {
		"name": "Drain Mastery",
		"base_value": 0.0,
		"per_level": 0.05,
		"base_cost": 80.0,
		"cost_exponent": 1.5,
		"format": "percent",
		"max_value": 0.5
	}
}

# --- Pump Definition ---
const PUMP_COST: float = 100.0
const PUMP_BASE_DRAIN: float = 0.001  # gal/sec
const PUMP_DRAIN_PER_LEVEL: float = 0.0005  # additional gal/sec per level
const PUMP_UPGRADE_BASE: float = 50.0

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
	"lucky_scoop": 0,
	"drain_mastery": 0
}

var current_stamina: float = 5.0

# Carrying water inventory
var water_carried: float = 0.0

# Hose state
var hose_active: bool = false
var hose_timer: float = 0.0
var hose_swamp_index: int = -1
const HOSE_DURATION: float = 20.0

# Pump state
var pump_owned: bool = false
var pump_level: int = 0
var pump_target_swamp: int = -1

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
	var value: float = defn["base_value"] + defn["per_level"] * stat_levels[stat_id]
	if defn.has("max_value"):
		value = minf(value, defn["max_value"])
	return value

func get_money_multiplier() -> float:
	return get_stat_value("water_value")

func get_lucky_scoop_chance() -> float:
	return get_stat_value("lucky_scoop")

func get_stamina_cost() -> float:
	return maxf(1.0 - get_stat_value("drain_mastery"), 0.5)

func get_max_stamina() -> float:
	return get_stat_value("stamina")

func get_stamina_regen_rate() -> float:
	return get_stat_value("stamina_regen")

func get_movement_speed_multiplier() -> float:
	return get_stat_value("movement_speed")

func get_tool_upgrade_cost(tool_id: String) -> float:
	var base_cost: float = tool_definitions[tool_id]["cost"]
	if base_cost == 0.0:
		base_cost = 5.0
	var level: int = tools_owned[tool_id]["level"]
	return base_cost * pow(1.15, level)

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
	var target: int = _get_pump_target_swamp()
	if target < 0:
		return 0.0
	return get_pump_drain_rate() * swamp_definitions[target]["money_per_gallon"]

func get_pump_upgrade_cost() -> float:
	return PUMP_UPGRADE_BASE * pow(1.15, pump_level)

func set_pump_target(swamp_index: int) -> void:
	if swamp_index < 0 or swamp_index >= swamp_definitions.size():
		pump_target_swamp = -1
	else:
		pump_target_swamp = swamp_index
	pump_changed.emit()

func _get_pump_target_swamp() -> int:
	if pump_target_swamp >= 0 and pump_target_swamp < swamp_definitions.size():
		if not swamp_states[pump_target_swamp]["completed"]:
			return pump_target_swamp
	return -1

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

	# Lucky scoop: chance to double
	var lucky: bool = false
	if randf() < get_lucky_scoop_chance():
		tool_output *= 2.0
		lucky = true

	var scoop_amount: float = minf(tool_output, remaining_space)

	current_stamina -= stamina_cost
	stamina_changed.emit(current_stamina, get_max_stamina())

	var actual: float = _drain_swamp(swamp_index, scoop_amount)
	if actual > 0.0:
		water_carried += actual
		water_carried_changed.emit(water_carried, capacity)
		scoop_performed.emit(swamp_index, actual, 0.0)
	return actual > 0.0

# sell_water: convert carried water to money (at sell point)
func sell_water() -> float:
	if water_carried <= 0.0001:
		return 0.0
	var mpg: float = 50.0 * get_money_multiplier()
	var earned: float = water_carried * mpg
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
		"lucky_scoop": 0,
		"drain_mastery": 0
	}
	current_stamina = get_max_stamina()
	water_carried = 0.0
	hose_active = false
	hose_timer = 0.0
	hose_swamp_index = -1
	pump_owned = false
	pump_level = 0
	pump_target_swamp = -1
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

	# Pump passive drain (earns money directly)
	if pump_owned:
		var target: int = _get_pump_target_swamp()
		if target >= 0:
			var gallons: float = get_pump_drain_rate() * delta
			drain_water(target, gallons)

func get_save_data() -> Dictionary:
	var swamp_save: Array = []
	for state in swamp_states:
		swamp_save.append({"gallons_drained": state["gallons_drained"], "completed": state["completed"]})
	return {
		"version": 5,
		"money": money,
		"current_tool_id": current_tool_id,
		"tools_owned": tools_owned.duplicate(true),
		"stat_levels": stat_levels.duplicate(true),
		"current_stamina": current_stamina,
		"water_carried": water_carried,
		"swamp_states": swamp_save,
		"pump_owned": pump_owned,
		"pump_level": pump_level,
		"pump_target_swamp": pump_target_swamp,
		"current_day": current_day
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

	# Pump
	pump_owned = data.get("pump_owned", false)
	pump_level = data.get("pump_level", 0)
	pump_target_swamp = data.get("pump_target_swamp", -1)
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

	# Emit signals
	money_changed.emit(money)
	for i in range(swamp_definitions.size()):
		water_level_changed.emit(i, get_swamp_water_percent(i))
	stamina_changed.emit(current_stamina, get_max_stamina())
	tool_changed.emit(tool_definitions[current_tool_id])
	pump_changed.emit()
	water_carried_changed.emit(water_carried, get_stat_value("carrying_capacity"))
