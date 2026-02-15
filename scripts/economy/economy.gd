class_name Economy

static func upgrade_cost(base_cost: float, level: int) -> float:
	return base_cost * pow(1.15, level)

static func format_money(amount: float) -> String:
	if amount >= 1000000.0:
		return "$%.2fM" % (amount / 1000000.0)
	elif amount >= 1000.0:
		return "$%.1fK" % (amount / 1000.0)
	elif amount >= 1.0:
		return "$%.2f" % amount
	else:
		return "$%.3f" % amount
