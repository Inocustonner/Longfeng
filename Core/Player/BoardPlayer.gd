extends Control

export var Nickname : String = "" setget set_nickname, get_nickname 

func _ready():
	pass # Replace with function body.

func set_nickname(value):
	Nickname = value
	$NameText.text = value

func get_nickname():
	return Nickname
