@tool
class_name Globals
extends Object

enum ResourceTaxonomies{
	FOOD,
	DRINK,
	
}

enum ResourceTypes{
	ENERGY,
	HYDRATION,
	NUTRITION,
	CALORIES,
	HYGIENE,
	PHYSICAL_HEALTH,
	MENTAL_HEALTH,
	MONEY,
	BREAD,
	RICE,
	VEGGIES,
	FRUITS,
	GRANOLA,
	YOGURT,
	COFFEE,
	MILK,
	PIZZA
}

enum WorldResourceTypes{
	
}


enum ActionTypes{
	READ_SECRETS,
	SCOUT,
	SCOPE,
	WASH,
	ASK,
	BEG,
	STEAL,
	WORK,
	SLEEP,
	COOK,
	GROW,
	RENT,
	GIVE,
}

enum LocationTypes{
	ALLEY,
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
	ActionTypes.READ_SECRETS : "Read",
	ActionTypes.SCOUT : "Scout",
	ActionTypes.SCOPE : "Scope",
	ActionTypes.BEG : "Beg",
	ActionTypes.STEAL : "Steal",
	ActionTypes.ASK : "Ask",
	ActionTypes.WORK : "Work",
	ActionTypes.COOK: "Cook",
	ActionTypes.GROW: "Grow",
	ActionTypes.GIVE: "Give",
}

static func get_action_string(action_type : ActionTypes) -> String:
	if action_type in _action_strings:
		return _action_strings[action_type]
	push_warning("no key matching type %s" % action_type)
	return ""
		
