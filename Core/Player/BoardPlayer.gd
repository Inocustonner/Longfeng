extends Control

export var Nickname : String = "" setget set_nickname, get_nickname 

var BoardsPlayer = [
	preload("res://Art/Sprites/Sprite_BoardPlayer_01.png"),
	preload("res://Art/Sprites/Sprite_BoardPlayer_02.png"),
	preload("res://Art/Sprites/Sprite_BoardPlayer_03.png"),
	preload("res://Art/Sprites/Sprite_BoardPlayer_04.png"),
	preload("res://Art/Sprites/Sprite_BoardPlayer_05.png"),
	preload("res://Art/Sprites/Sprite_BoardPlayer_06.png")
]

func set_nickname(value):
	Nickname = value
	$NameText.text = value

func get_nickname():
	return Nickname

# idx - номер с которым игрок подключился
func set_background(idx):
	$Background.texture = BoardsPlayer[idx]
