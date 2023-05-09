extends Control

# Массив секций. Первое значение где начинается, второе где заканчивается
const PositionSections = [
	[0, 36],
	[37, 75],
	[76, 113]
]

# Минимальное количество ходов на одной секции
const MIN_MOVES_ON_SECTION = 17

signal on_started_discussion
signal on_ended_discussion
signal on_player_want_move
signal on_player_start_trade_card(card_name)
signal on_player_stop_trade_card
signal on_started_trading_between_players(main_trader, type_tradeing)
signal on_make_trade(ChooisedPlayerId)
signal on_player_end_playing(playerid)

var PlayerController = preload("res://Core/Player/BoardPlayer.tscn")

var SpritesDice = [
	preload("res://Art/Sprites/Sprite_Dice.png"),
	preload("res://Art/Sprites/Sprite_Dice_1.png"),
	preload("res://Art/Sprites/Sprite_Dice_2.png"),
	preload("res://Art/Sprites/Sprite_Dice_3.png"),
	preload("res://Art/Sprites/Sprite_Dice_4.png"),
	preload("res://Art/Sprites/Sprite_Dice_5.png"),
	preload("res://Art/Sprites/Sprite_Dice_6.png")
]

var ColorsPlayer = [
	"#d30c7b", "#a7abdd", "#12a0a0",
	"#0a8754", "#535353", "#16c612"
]

onready var PlayerListText = $BottomPanel/HBoxContainer/VBoxContainer2/PlayerListText
onready var Board = $Board
onready var CardsListPlayer = $CardsListPlayer
onready var NewCard = $NewCard
onready var CuratorNewCard = $CuratorNewCard
onready var IndicatorMove = $BottomPanel/HBoxContainer/VBoxContainer
onready var ChangeScreen = $ChangeScreen
onready var CloseCardsButton = $CloseCardsButton

func _ready():
	ChangeScreen.connect("on_start_trade_card", self, "_on_start_trade_card")
	ChangeScreen.connect("on_stop_trade_card", self, "_on_stop_trade_card")
	ChangeScreen.connect("on_make_trade", self, "_on_make_trade")
	Board.connect("completed_move", self, "_on_completed_move_on_board")
	pass 

func add_player(id):
	PlayerListText.bbcode_text = "[center]Игроки:\n"
	var row_amount = 0
	for player in Lobby.player_info:
		PlayerListText.bbcode_text += "[color="+ColorsPlayer[Lobby.player_info[player].position_list] + "]" + Lobby.player_info[player].name + "[/color] "
		row_amount += 1
		if(row_amount == 2):
			PlayerListText.bbcode_text += "\n"
			row_amount = 0
	PlayerListText.bbcode_text += "[/center]"

	var ply = PlayerController.instance()
	Lobby.player_info[id].obj = ply
	ply.name = str(id)
	call_deferred("add_child", ply)
	ply.set_nickname(Lobby.player_info[id].name)
	ply.set_background(Lobby.player_info[id].position_list)
	
	ChangeScreen.add_player(id)
	return ply

# Ставит игрока на конкретное поле на доске
# Первый параметр это id игрока. Второй позиция от 0 на какое поле его поставить
func set_player_position(id, position):
	Board.set_player_to_board(Lobby.player_info[id].obj, position)
	# Важно чтобы set_player_to_board был выше, чем установка позиции в общий список!
	Lobby.player_info[id].position = position

# Инкрементирует позицию игрока на доске. Запускать только на сервере!
# Первый параметр это id игрока.
func increment_player_position(id, i : int):
	Lobby.player_info[id].amount_moves += 1
	if(_get_section_from_position(Lobby.player_info[id].position) != _get_section_from_position(Lobby.player_info[id].position + i)):
		if(Lobby.player_info[id].amount_moves < MIN_MOVES_ON_SECTION):
			var now_sec = _get_section_from_position(Lobby.player_info[id].position)
			var amount_board_in_sec = PositionSections[now_sec][1] - PositionSections[now_sec][0]
			var next_pos = int((Lobby.player_info[id].position + i) % amount_board_in_sec)
			if(next_pos == 0):
				next_pos = 1
			set_player_position(id, next_pos)
			do_move(id)
			return
		else:
			Lobby.player_info[id].amount_moves = 0
		
	if(Lobby.player_info[id].position >= PositionSections[2][1]):
		set_player_position(id, PositionSections[2][1])
		emit_signal("on_player_end_playing", id)
		return
	set_player_position(id, Lobby.player_info[id].position + i)
	do_move(id)

# Производит ход. Происходит в зависимости на чем стоит игрок
func do_move(id):
	match(Board.get_field(Lobby.player_info[id].position).Type):
		0:
			add_card_to_player(id)
		1: # START
			pass
		2: # FINISH
			emit_signal("on_player_end_playing", id)
		3: # Осознанность
			add_card_to_player(id)
		4: # Секрет
			add_card_to_player(id)
		5: # Взаимодействие
			if(Lobby.player_info[id].position < PositionSections[0][1]):
				emit_signal("on_started_trading_between_players", id, rand_range(0,1))
			else:
				emit_signal("on_started_trading_between_players", id, 0)
		6: # Событие
			emit_signal("on_ended_discussion")
		7: # Ловушка
			Lobby.player_info[id].amount_moves = 0
			add_card_to_player(id)
			if(Lobby.player_info[id].position <= PositionSections[0][1]):
				set_player_position(id, PositionSections[0][0])
			else: if(Lobby.player_info[id].position <= PositionSections[1][1]):
				set_player_position(id, PositionSections[1][0])
			else: if(Lobby.player_info[id].position <= PositionSections[2][1]):
				set_player_position(id, PositionSections[2][0])
		8: # Сам себе хозяин
			if(rand_range(0,1) == 0):
				set_player_position(id, PositionSections[_get_section_from_position(Lobby.player_info[id].position) + 1][0])
			else:
				set_player_position(id, rand_range(PositionSections[_get_section_from_position(Lobby.player_info[id].position)][0], PositionSections[_get_section_from_position(Lobby.player_info[id].position)][1]))
			add_card_to_player(id)

func add_card_to_player(id):
	var card = Utility.create_card(Board.get_field(Lobby.player_info[id].position).Description)
	Lobby.player_info[id].cards.append(card)
	_show_to_currator_new_card(card.Name, card.Description)
	emit_signal("on_started_discussion")
	rpc("add_card_to_player_CLIENT", id, card)

func show_card_to_player(id, category):
	var card = Utility.create_card(category)
	Lobby.player_info[id].cards.append(card)
	_show_to_currator_new_card(card.Name, card.Description)
	emit_signal("on_started_discussion")
	rpc_id(id, "_show_card_to_player", card.Name)

func show_card_to_player_without_add(id, card_name):
	_show_to_currator_new_card(card_name, "Это карта не имеет описания!")
	emit_signal("on_started_discussion")
	rpc_id(id, "_show_card_to_player", card_name)

remote func add_card_to_player_CLIENT(id, card):
	Lobby.player_info[id].cards.append(card)
	if(get_tree().get_network_unique_id() == id):
		show_new_card_to_player()
		CardsListPlayer.add_card(card)

remote func _show_card_to_player(card_name):
	NewCard.get_child(0).text = card_name

func show_new_card_to_player():
	NewCard.get_child(0).text = Lobby.player_info[get_tree().get_network_unique_id()].cards[len(Lobby.player_info[get_tree().get_network_unique_id()].cards) - 1].Name

func hide_new_card_to_player():
	NewCard.hide()

func show_amount_moves(moves):
	IndicatorMove.get_child(1).get_child(0).texture = SpritesDice[moves]
	var timer := Timer.new()
	add_child(timer)
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.start()
	timer.connect("timeout", self, "_hide_amount_moves")

func _hide_amount_moves():
	IndicatorMove.get_child(1).get_child(0).texture = SpritesDice[0]

# Возвращает номер секции (от 0) в которой находится позиция
func _get_section_from_position(position):
	for i in range(0, len(PositionSections)):
		if(position >= PositionSections[i][0] and position <= PositionSections[i][1]):
			return i

func let_make_move(bLet : bool):
	if(bLet):
		IndicatorMove.get_child(0).get_child(0).text = "Ваш ход!"
		IndicatorMove.get_child(1).show()
	else:
		IndicatorMove.get_child(0).get_child(0).text = "Сейчас ходите не вы!"
		IndicatorMove.get_child(1).hide()

func hide_button_move():
	IndicatorMove.hide()

func show_change_screen_to_player(bShow, main_trader, type_tradeing):
	ChangeScreen.show_screen(bShow, main_trader, type_tradeing)

# Вкл/Выкл зеленую лампочку для показания желания обмена игрока
func set_active_for_change_card(id, bActive):
	ChangeScreen.set_active_player(id, bActive)

func update_player_trades(playerid, card_name):
	ChangeScreen.update_trades(playerid, card_name)

func _show_to_currator_new_card(name_card, desc):
	CuratorNewCard.get_child(1).disabled = true
	CuratorNewCard.get_child(0).get_child(0).text = name_card
	CuratorNewCard.get_child(2).get_child(0).get_child(0).text = desc
	CuratorNewCard.show()
	var timer := Timer.new()
	add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.start()
	timer.connect("timeout", self, "_enable_button_currator")

func _enable_button_currator():
	CuratorNewCard.get_child(1).disabled = false

# Показать карты игрока
func _on_Button_pressed():
	if(CardsListPlayer.visible):
		CardsListPlayer.visible = false
		CloseCardsButton.visible = false
	else:
		CardsListPlayer.visible = true
		CloseCardsButton.visible = true


func _on_ButtonEndDisc_pressed():
	emit_signal("on_ended_discussion")
	CuratorNewCard.hide()

func _on_ButtonMakeMove_pressed():
	emit_signal("on_player_want_move")

func _on_start_trade_card(card_name):
	emit_signal("on_player_start_trade_card", card_name)

func _on_stop_trade_card():
	emit_signal("on_player_stop_trade_card")

func _on_make_trade(ChooisedPlayerId):
	emit_signal("on_make_trade", ChooisedPlayerId)

func _on_completed_move_on_board():
	NewCard.show()


func _on_CloseCardsButton_pressed():
	CardsListPlayer.visible = false
	CloseCardsButton.visible = false
