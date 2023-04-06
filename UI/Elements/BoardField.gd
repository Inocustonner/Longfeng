extends Control

enum ETypeBoard {DEFAULT, START, FINISH, AWARENESS, SECRET, INTERACTION, EVENT, TRAP, YOUROWNBOSS}

export (ETypeBoard) var Type = ETypeBoard.DEFAULT
export var Position : int = 1 setget set_board_position, get_board_position
export var Description : String = "TEST" setget set_board_desc, get_board_desc

onready var BGSprite = $Sprite
onready var LabelPosition = $Position
onready var Text = $Text

func _ready():
	LabelPosition.text = str(Position)
	Text.text = Description
	
	match(Type):
		ETypeBoard.DEFAULT:
			BGSprite.texture = preload("res://Art/Sprites/Sprite_BoardField_Default.png")
		ETypeBoard.START:
			BGSprite.texture = preload("res://Art/Sprites/Sprite_BoardField_Start.png")
			Text.hide()
			LabelPosition.hide()
		ETypeBoard.FINISH:
			BGSprite.texture = preload("res://Art/Sprites/Sprite_BoardField_Finish.png")
			Text.hide()
			LabelPosition.hide()
		ETypeBoard.AWARENESS:
			BGSprite.texture = preload("res://Art/Sprites/Sprite_BoardField_Awareness.png")
			Text.hide()
			LabelPosition.hide()
		ETypeBoard.SECRET:
			BGSprite.texture = preload("res://Art/Sprites/Sprite_BoardField_Secret.png")
			Text.hide()
			LabelPosition.hide()
		ETypeBoard.INTERACTION:
			BGSprite.texture = preload("res://Art/Sprites/Sprite_BoardField_Interaction.png")
			Text.hide()
			LabelPosition.hide()
		ETypeBoard.EVENT:
			BGSprite.texture = preload("res://Art/Sprites/Sprite_BoardField_Awareness.png")
			LabelPosition.hide()

func set_board_position(value):
	Position = value
	LabelPosition.text = str(value)

func get_board_position():
	return Position

func set_board_desc(value):
	Description = value
	Text.text = value

func get_board_desc():
	return Description
