extends Button

signal on_change_card_pressed(button)

var Clickable = true

func _ready():
	pass # Replace with function body.

func set_name_card(namecard):
	$Card/NameText.text = namecard

func get_name_card():
	return $Card/NameText.text

func _on_Button_pressed():
	if(Clickable):
		emit_signal("on_change_card_pressed", get_node("."))
