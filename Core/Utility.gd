extends Node

func read_json_file(file_path: String) -> Dictionary:
	var file = File.new()
	file.open(file_path, File.READ)
	var json_text = file.get_as_text()
	file.close()

	var json_dict = parse_json(json_text)
	return json_dict

var Cards = read_json_file("res://Data/Cards.json")
#var Cards = read_json_file("user://Cards.json")
# Создает случайную карту из категории
func create_card(category : String):
	var card = {}
	var pos = rand_range(0, len(Cards[category]) - 1)
	card.Name = Cards[category][pos]["name"]
	card.Description = Cards[category][pos]["long_description"]
	card.Type = Cards[category][pos]["positivity"]
	card.Category = category
	return card

func create_card_by_name_card(name_card : String):
	for categories in Cards:
		for i in Cards[categories]:
			if(i["name"] == name_card):
				var card = {}
				card.Name = i["name"]
				card.Description = i["long_description"]
				card.Type = i["positivity"]
				card.Category = categories
				return card
	return null
