extends Control

# Константа определяющая является ли эта версия серверной.
const SERVER_VERSION = true

onready var NameEdit = $CenterPanel/VBoxContainer/HBoxContainer2/NameEdit
onready var IPEdit = $CenterPanel/VBoxContainer/HBoxContainer4/IPEdit
onready var SessionEdit = $CenterPanel/VBoxContainer/HBoxContainer6/SessionEdit
onready var PlayButton = $CenterPanel/VBoxContainer/HBoxContainer9/PlayButton
onready var CheckBox1 = $CenterPanel/VBoxContainer/HBoxContainer8/CheckBox1
onready var CheckBox2 = $CenterPanel/VBoxContainer/HBoxContainer8/CheckBox2
onready var CheckBox3 = $CenterPanel/VBoxContainer/HBoxContainer8/CheckBox3

func _ready():
	if(SERVER_VERSION):
		$CenterPanel/VBoxContainer/HBoxContainer5.hide()
		$CenterPanel/VBoxContainer/HBoxContainer6.hide()
		$CenterPanel/VBoxContainer/HBoxContainer9/PlayButton.text = "Создать игру"
	else:
		$CenterPanel/VBoxContainer/HBoxContainer7.hide()
		$CenterPanel/VBoxContainer/HBoxContainer8.hide()
		$CenterPanel/VBoxContainer/HBoxContainer9/PlayButton.text = "Присоединиться"
	pass

func _on_NameEdit_text_changed(_new_text):
	pass


func _on_CheckBox1_toggled(button_pressed):
	if(button_pressed):
		Lobby.start_section = 0
		CheckBox2.pressed = false
		CheckBox3.pressed = false


func _on_CheckBox2_toggled(button_pressed):
	if(button_pressed):
		Lobby.start_section = 1
		CheckBox1.pressed = false
		CheckBox3.pressed = false


func _on_CheckBox3_toggled(button_pressed):
	if(button_pressed):
		Lobby.start_section = 2
		CheckBox2.pressed = false
		CheckBox1.pressed = false


func _on_PlayButton_pressed():
	if not SERVER_VERSION:
		if(len(IPEdit.text) > 0 and len(NameEdit.text) > 0):
			Lobby.my_player_info.name = NameEdit.text
			Network.connect_to_server(IPEdit.text, 7777)
	else:
		if(len(NameEdit.text) > 0 and Lobby.start_section != -1):
			Lobby.my_player_info.name = NameEdit.text
			Network.create_server(7777,6)
