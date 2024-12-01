@tool
class_name Globals
extends Object

enum ActionTypes{
	NONE = -1,
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
	SCAVENGE,
	GIVE,
	ADVOCATE,
	LIBERATE,
	EAT,
	ORGANIZE,
}

enum LocationTypes{
	NONE = -1,
	APARTMENTS,
	GROCERY_STORE,
	BAKERY,
	SUPERMARKET,
	FARMERS_MARKET,
	BANK,
	BAR,
	PARK,
	CHURCH,
	CONDOS,
	MOTEL,
	HOTEL,
	RESTAURANT,
	CAFE,
	OFFICES,
	GARDENING_STORE,
	GUN_STORE,
	CLOTHING_STORE,
	CRAFTS_STORE,
	COSTUME_STORE,
	GAS_STATION,
	POLICE_STATION,
	FIRE_STATION,
	PHARMACY,
	HOSPITAL,
	HOMELESS_SHELTER,
	UNIVERSITY,
	BUS_STATION,
	TRAIN_STATION,
}

class LocationAction:
	var location_type : Globals.LocationTypes
	var action_type : Globals.ActionTypes
	
	func get_string():
		return "%s at %s" % [Globals.get_action_string(action_type), Globals.get_location_string(location_type)]

class Bonus:
	var bonus : float 
	
	func get_multiplier():
		return 1 + bonus

class ResourceBonus extends Bonus:
	var resource_name : StringName

class ActionResourceBonus extends ResourceBonus:
	var action_type : Globals.ActionTypes

class LocationActionResourceBonus extends ActionResourceBonus:
	var location_type : Globals.LocationTypes

static var _action_strings : Dictionary = {
	ActionTypes.READ : "Read",
	ActionTypes.SCOUT : "Scout",
	ActionTypes.REST : "Rest",
	ActionTypes.WORK : "Work",
	ActionTypes.BUY : "Buy",
	ActionTypes.SELL : "Sell",
	ActionTypes.BEG : "Ask/Beg",
	ActionTypes.STEAL : "Steal",
	ActionTypes.CRAFT : "Craft",
	ActionTypes.COOK: "Cook",
	ActionTypes.GROW: "Grow",
	ActionTypes.GIVE: "Give",
	ActionTypes.ADVOCATE: "Advocate",
	ActionTypes.LIBERATE: "Liberate",
	ActionTypes.EAT: "Eat",
	ActionTypes.SCAVENGE: "Scavenge",
	ActionTypes.ORGANIZE: "Organize"
}

static var _location_strings : Dictionary = {
	LocationTypes.APARTMENTS : "Apartments",
	LocationTypes.GROCERY_STORE : "Grocery Store",
	LocationTypes.BAKERY : "Bakery",
	LocationTypes.SUPERMARKET : "Supermarket",
	LocationTypes.FARMERS_MARKET : "Farmer's Market",
	LocationTypes.BANK : "Bank",
	LocationTypes.BAR : "Bar",
	LocationTypes.PARK : "Park",
	LocationTypes.CHURCH : "Church",
	LocationTypes.CONDOS : "Condos",
	LocationTypes.MOTEL : "Motel",
	LocationTypes.HOTEL : "Hotel",
	LocationTypes.RESTAURANT : "Restaurant",
	LocationTypes.CAFE : "Cafe",
	LocationTypes.OFFICES : "Offices",
	LocationTypes.GAS_STATION : "Gas Station",
	LocationTypes.GARDENING_STORE : "Gardening Store",
	LocationTypes.GUN_STORE : "Gun Store",
	LocationTypes.CLOTHING_STORE : "Clothing Depot",
	LocationTypes.CRAFTS_STORE : "Crafts Store",
}

static var _base_action_risks : Dictionary[ActionTypes, float] = {
	ActionTypes.READ : 0,
	ActionTypes.SCOUT : 0,
	ActionTypes.REST : 0,
	ActionTypes.WORK : 0,
	ActionTypes.BUY : 0,
	ActionTypes.SELL : 0.5,
	ActionTypes.BEG : 0.25,
	ActionTypes.STEAL : 0.5,
	ActionTypes.COOK: 0,
	ActionTypes.GROW: 0.25,
	ActionTypes.GIVE: 0,
	ActionTypes.ADVOCATE: 0,
	ActionTypes.LIBERATE: 0,
	ActionTypes.EAT: 0,
	ActionTypes.SCAVENGE: 0.25,
	ActionTypes.ORGANIZE: 0.25
}

static var _action_risky_resources : Dictionary[ActionTypes, Array] = {
	ActionTypes.READ : [],
	ActionTypes.SCOUT : [],
	ActionTypes.REST : [&"fatigue", &"suspicion"],
	ActionTypes.WORK : [&"suspicion", &"evidence"],
	ActionTypes.BUY : [&"suspicion", &"evidence"],
	ActionTypes.SELL : [],
	ActionTypes.BEG : [ &"fatigue", &"suspicion"],
	ActionTypes.STEAL : [&"suspicion", &"evidence"],
	ActionTypes.COOK: [],
	ActionTypes.GROW: [],
	ActionTypes.GIVE: [],
	ActionTypes.ADVOCATE: [&"fatigue", &"suspicion"],
	ActionTypes.LIBERATE: [],
	ActionTypes.EAT: [],
	ActionTypes.SCAVENGE: [&"suspicion"],
	ActionTypes.ORGANIZE: [&"fatigue", &"suspicion", &"evidence"]
}

static func get_action_risk(action_type : ActionTypes) -> float:
	if action_type in _base_action_risks:
		return _base_action_risks[action_type]
	push_warning("no key matching type %s" % action_type)
	return 0.0

static func get_action_risky_resources(action_type : ActionTypes) -> Array:
	if action_type in _action_risky_resources:
		return _action_risky_resources[action_type]
	push_warning("no key matching type %s" % action_type)
	return []

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

static func get_resource_unit(resource_name : StringName) -> ResourceUnit:
	if game_resources.is_empty(): _fill_game_resources()
	for resource_unit in game_resources:
		if resource_unit.name == resource_name:
			return resource_unit
	push_warning("resource matching '%s' not found" % resource_name)
	return

static func get_resource_quantity(resource_name : StringName) -> ResourceQuantity:
	var new_quantity = ResourceQuantity.new()
	new_quantity.resource_unit = get_resource_unit(resource_name)
	return new_quantity

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
