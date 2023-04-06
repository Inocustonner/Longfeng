extends TabContainer

onready var CARD = preload("res://UI/Elements/Card.tscn")
onready var NegativeContainer = $"Негативные установки/NegativeContainer/GridContainer"
onready var PositiveContainer = $"Позитивные установки/PositiveContainer/GridContainer"

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
	for i in PositiveContainer.get_children():
		if(i.get_child(0).text == card_name):
			PositiveContainer.remove_child(i)
			i.queue_free()
			return
	for i in NegativeContainer.get_children():
		if(i.get_child(0).text == card_name):
			NegativeContainer.remove_child(i)
			i.queue_free()
			return
