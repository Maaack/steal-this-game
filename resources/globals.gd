@tool
class_name Globals
extends Object

enum ActionTypes{
	READ,
	SCOUT,
	REST,
	WORK,
	BUY,
	SELL,
	BEG,
	STEAL,
	COOK,
	CRAFT,
	GROW,
	RENT,
	GIVE,
	ADVOCATE,
	LIBERATE,
}

enum LocationTypes{
	APARTMENTS,
	OFFICES,
	GAS_STATION,
	LIQUOR_STORE,
	GROCERY_STORE,
	FARMERS_MARKET,
	BAKERY,
	SUPERMARKET,
	BANK,
	BAR,
	PARK,
	CHURCH,
	CONDOS,
	LOCAL_MOTEL,
	CHAIN_MOTEL,
	LOCAL_HOTEL,
	CHAIN_HOTEL,
	FANCY_HOTEL,
	FAST_FOOD_RESTAURANT,
	LOCAL_RESTAURANT,
	CHAIN_RESTAURANT,
	FANCY_RESTAURANT,
	DINER,
	COFFEE_SHOP,
	GARDENING_STORE,
	GUN_STORE,
	DISCOUNT_CLOTHING_STORE,
	CHAIN_CLOTHING_STORE,
	FASHION_STORE,
	COSTUME_STORE,
	POLICE_STATION,
	FIRE_STATION,
	PHARMACY,
	HOSPITAL,
	HOMELESS_SHELTER,
	UNIVERSITY,
	BUS_STATION,
	TRAIN_STATION,
}

static var _action_strings : Dictionary = {
	ActionTypes.READ : "Read",
	ActionTypes.SCOUT : "Scout",
	ActionTypes.REST : "Rest",
	ActionTypes.WORK : "Work",
	ActionTypes.BUY : "Buy",
	ActionTypes.SELL : "Sell",
	ActionTypes.BEG : "Beg",
	ActionTypes.STEAL : "Steal",
	ActionTypes.COOK: "Cook",
	ActionTypes.GROW: "Grow",
	ActionTypes.GIVE: "Give",
	ActionTypes.ADVOCATE: "Advocate",
	ActionTypes.LIBERATE: "Liberate",
}

static var _location_strings : Dictionary = {
	LocationTypes.APARTMENTS : "Apartments",
	LocationTypes.BAKERY : "Bakery",
	LocationTypes.SUPERMARKET : "Supermarket",
	LocationTypes.GROCERY_STORE : "Grocery Store",
	LocationTypes.CHAIN_CLOTHING_STORE : "Clothing Depot Chain",
}

static func get_action_string(action_type : ActionTypes) -> String:
	if action_type in _action_strings:
		return _action_strings[action_type]
	push_warning("no key matching type %s" % action_type)
	return ""

static func get_location_string(location_type : LocationTypes) -> String:
	if location_type in _location_strings:
		return _location_strings[location_type]
	push_warning("no key matching type %s" % location_type)
	return ""

static var game_resources : Array[ResourceUnit]

static func _fill_game_resources():
	var dir_access = DirAccess.open("res://resources/game_resources/")
	for file in dir_access.get_files():
		if file.ends_with(".remap"):
			file = file.trim_suffix(".remap")
		var resource_unit : Resource = load("res://resources/game_resources/%s" % file)
		if resource_unit is ResourceUnit:
			game_resources.append(resource_unit)

static func get_resource_unit(resource_name : String) -> ResourceUnit:
	if game_resources.is_empty(): _fill_game_resources()
	for resource_unit in game_resources:
		if resource_unit.name == resource_name:
			return resource_unit
	push_warning("resource matching '%s' not found" % resource_name)
	return

static func get_comma_separated_list(strings : Array[String]) -> String:
	if strings.size() > 2:
		var last_string = strings.pop_back()
		return ", ".join(strings) + " and " + last_string
	elif strings.size() == 2:
		return strings[0] + " and " + strings[1]
	elif strings.size() == 1:
		return strings[0]
	else:
		return ""
