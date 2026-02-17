class_name Economy

static func upgrade_cost(base_cost: float, level: int) -> float:
	return base_cost * pow(1.15, level)

const MONEY_SUFFIXES: Array[Array] = [
	[1e18, " Qi"],   # Quintillion
	[1e15, " Qa"],   # Quadrillion
	[1e12, " T"],    # Trillion
	[1e9,  " B"],    # Billion
	[1e6,  " M"],    # Million
	[1e3,  " K"],    # Thousand
]

static func format_money(amount: float) -> String:
	for tier in MONEY_SUFFIXES:
		if amount >= tier[0]:
			var val: float = amount / tier[0]
			if val >= 100.0:
				return "$%.0f%s" % [val, tier[1]]
			elif val >= 10.0:
				return "$%.1f%s" % [val, tier[1]]
			else:
				return "$%.2f%s" % [val, tier[1]]
	if amount >= 1.0:
		return "$%.2f" % amount
	else:
		return "$%.3f" % amount
