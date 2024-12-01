@tool
extends Credits

func is_end_reached():
	var _end_of_credits_vertical = %CreditsLabel.size.y + %HeaderSpace.size.y + %TextureRect.size.y
	return $ScrollContainer.scroll_vertical > _end_of_credits_vertical
