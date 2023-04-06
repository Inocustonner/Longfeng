extends Button

signal on_player_lot_pressed(button)

func _ready():
	pass # Replace with function body.

func set_nickname(nick):
	$HBoxContainer/Label.text = nick

func set_active(bActive):
	if(bActive):
		$HBoxContainer/TextureRect.texture = preload("res://Art/Sprites/Sprite_AgreeLot.png")
	else:
		$HBoxContainer/TextureRect.texture = preload("res://Art/Sprites/Sprite_DisagreeLot.png")


func _on_Button_pressed():
	emit_signal("on_player_lot_pressed", get_node("."))
