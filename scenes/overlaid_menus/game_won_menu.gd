extends GameWonMenu

const WIN_STRING = "[center]You liberated %s!\nYou took\n%d minutes and %d seconds\n of game time![/center]"

var city_name : String
var game_time : float

func _ready():
	var _minutes = int(game_time) / 60
	var _seconds = int(game_time) % 60
	%DescriptionLabel.text = WIN_STRING % [city_name, _minutes, _seconds]
