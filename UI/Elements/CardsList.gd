extends TabContainer

onready var CARD = preload("res://UI/Elements/Card.tscn")

func _ready():
	pass # Replace with function body.

func add_card(card):
	var new_card = CARD.instance()
	new_card.get_child(0).text = card.Name
	for child in get_children():
		if(child.name.to_lower() == card.Category.to_lower()):
			child.get_node("ScrollContainer/GridContainer").add_child(new_card)
			break

func remove_card(card_name):
	for tab in get_children():
		for cards in tab.get_child(0).get_child(0).get_children():
			if(cards.get_child(0).text == card_name):
				tab.get_child(0).get_child(0).remove_child(cards)
				cards.queue_free()
				return
