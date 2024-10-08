extends Node


const NO_BODY_GO = -1


onready var Game = $Game
onready var MainMenu = $MainMenu



# Состояние игры, если активно значит игроки обсуждают ход и сделать новый нельзя.
master var bDiscussion : bool = false
# Игрок делающий ход сейчас.
# Здесь хранится номер элемента из списка player_info в Lobby.
# Делать ход обязательно в методе _next_player, не самому.
master var PlayerNow : int = NO_BODY_GO
# Id игрока, который является главным трейлеров (тот кто встал на взаимодействие)
master var MainTraderId = 0

func _ready():
	Network.connect("on_created_server", self, "_on_connected_to_server") 
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	Lobby.connect("on_player_released", self, "_on_player_released")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	Game.connect("on_started_discussion", self, "_on_players_started_discussion")
	Game.connect("on_ended_discussion", self, "_on_players_ended_discussion")
	Game.connect("on_player_want_move", self, "_on_player_want_move")
	Game.connect("on_player_start_trade_card", self, "_on_player_start_trade_card")
	Game.connect("on_player_stop_trade_card", self, "_on_player_stop_trade_card")
	Game.connect("on_started_trading_between_players", self, "_on_started_trading_between_players")
	Game.connect("on_make_trade", self, "_on_make_trade")
	Game.connect("on_player_end_playing", self, "_on_player_end_playing")
	Game.connect("on_player_want_to_set_pos", self, "_on_player_want_to_set_pos")


func _next_player():
	var bAllEnded = true

	for id in Lobby.player_ids:
		if (Lobby.player_info[id].is_end_game == false):
			bAllEnded = false
			break

	if(bAllEnded):
		PlayerNow = NO_BODY_GO
		return

	if(len(Lobby.player_ids) == 1):
		PlayerNow = 0
		return
	
	PlayerNow += 1
	if(PlayerNow > len(Lobby.player_ids) - 1):
		PlayerNow = 0

	while Lobby.player_info[Lobby.player_ids[PlayerNow]].is_end_game == true:
		PlayerNow += 1
		if(PlayerNow > len(Lobby.player_ids) - 1):
			PlayerNow = 0


func _get_prev_player_id():
	if(len(Lobby.player_ids) == 1):
		return Lobby.player_ids[PlayerNow]
	
	var bAllEnded = true

	for id in Lobby.player_ids:
		if (Lobby.player_info[id].is_end_game == false):
			bAllEnded = false
			break
			
	var i = PlayerNow
	if(i == 0):
		i = len(Lobby.player_ids) - 1
	else:
		i -= 1
	
	if(bAllEnded):
		return Lobby.player_ids[i]
	# Пропускаем тех, кто окончил игру по аналогии с _next_player()
	while Lobby.player_info[Lobby.player_ids[i]].is_end_game == true:
		i =- 1
		if(i < 0):
			i = len(Lobby.player_ids) - 1
			
	return Lobby.player_ids[i]


master func _player_want_to_move():
	if(bDiscussion):
		return

	if Lobby.player_info[get_tree().get_rpc_sender_id()].is_end_game:
		return

	if(Lobby.player_ids[PlayerNow] == get_tree().get_rpc_sender_id()):
		var id = get_tree().get_rpc_sender_id()
		# Генерируем случайное целое число между 1 и 6
		var moves = 1 + randi() % 6
		var FieldType = Game.Board.get_field(Lobby.player_info[id].position + moves).Type
		# Если попадаем на "Засада", то с вероятностью 50% генерируем новое число
		if (FieldType == Game.BoardField.ETypeBoard.TRAP \
			and randi() % 2 == 1):
			moves = 1 + randi() % 6
		# Если попадаем на "Финиш" или выходим за доску, то вычисляем точное расстояние до клетки, чтобы избежать ошибок
		if (FieldType == Game.BoardField.ETypeBoard.FINISH):
			moves = Game.Board.BoardFields.get_child_count() - 1 - Lobby.player_info[id].position
			
		Game.increment_player_position(get_tree().get_rpc_sender_id(), moves)
		rpc("_make_move", get_tree().get_rpc_sender_id(), Lobby.player_info[id].position, moves)
		_next_player()


master func _player_want_to_trade(card_name):
	var playerid = get_tree().get_rpc_sender_id()
	Lobby.player_trade_lots[playerid] = card_name
	rpc("_update_player_trade_lots", playerid, card_name)
	rpc("_player_want_to_change_card", playerid, true)


master func _player_dont_want_to_trade():
	rpc("_player_want_to_change_card", get_tree().get_rpc_sender_id(), false)


master func _player_maked_trade(ChooisedPlayerId):
	if(get_tree().get_rpc_sender_id() != MainTraderId):
		return

	var cpi = int(ChooisedPlayerId)

	if(cpi == 0):
		return

	if(Lobby.player_trade_lots[MainTraderId] == null):
		return
	
	rpc("_trade_cards_between_players",
		MainTraderId, cpi, Lobby.player_trade_lots[MainTraderId], Lobby.player_trade_lots[cpi])
	
	rpc("_show_to_players_change_screen", false, 0, 0)
	_on_players_ended_discussion()


master func _move_player_to_him_pos(new_pos):
	rpc("_ALL_move_player_to_him_pos", get_tree().get_rpc_sender_id(), new_pos)


remotesync func _ALL_move_player_to_him_pos(playerid, new_pos):
	Game.set_player_position(playerid, new_pos)
	_on_players_ended_discussion()


remotesync func _make_move(playerid, position, moves):
	if(get_tree().get_network_unique_id() == playerid):
		Game.show_amount_moves(moves)
	
	Game.set_player_position(playerid, position)


remotesync func _trade_cards_between_players(playerid, playerid2, card_name, card_name2):
	_give_card_to_player(playerid, card_name2)
	_give_card_to_player(playerid2, card_name)
	_remove_card_from_player(playerid, card_name)
	_remove_card_from_player(playerid2, card_name2)


remotesync func _give_card_to_player(playerid, card_name):
	var card = Utility.create_card_by_name_card(card_name)
	Lobby.player_info[int(playerid)].cards.append(card)
	if(get_tree().get_network_unique_id() == int(playerid)):
		Game.CardsListPlayer.add_card(card)


remotesync func _remove_card_from_player(playerid, card_name):
	for card in Lobby.player_info[int(playerid)].cards:
		if card.Name == card_name:
			Lobby.player_info[int(playerid)].cards.erase(card)

	if(get_tree().get_network_unique_id() == playerid):
		Game.CardsListPlayer.remove_card(card_name)


remote func _hide_new_card():
	Game.hide_new_card_to_player()


remote func _let_player_make_move(bLet : bool):
	Game.let_make_move(bLet)


remote func _player_maked_move():
	pass


#remote func _player_stop_game():
#	$Game/BottomPanel/HBoxContainer/VBoxContainer/HBoxContainer2/Button.disabled = true


remote func _player_want_to_change_card(id, bActive):
	Game.set_active_for_change_card(id, bActive)


remote func _show_to_players_change_screen(bShow, main_trader, type_tradeing):
	MainTraderId = main_trader
	Game.show_change_screen_to_player(bShow, main_trader, type_tradeing)


remote func _update_player_trade_lots(playerid, card_name):
	Lobby.player_trade_lots[playerid] = card_name
	Game.update_player_trades(playerid, card_name)


func _on_connected_to_server():
	Game.show()
	MainMenu.hide()
	
	if(get_tree().is_network_server()):
		Game.hide_button_move()


func _on_player_released(id):
	Game.add_player(id)
	Game.refresh_playerlist()

	if(Lobby.player_info[id].position == -1):
		Lobby.player_info[id].position = Game.PositionSections[Lobby.start_section][0]

	Game.Board.set_player_to_actual_position(Lobby.player_info[id].obj, Lobby.player_info[id].position)

	if(not get_tree().is_network_server() and id == get_tree().get_network_unique_id()):
		Game.load_all_cards()

	if(get_tree().is_network_server()):
		if(PlayerNow == NO_BODY_GO):
			_next_player()
		rpc_id(int(Lobby.player_ids[PlayerNow]), "_let_player_make_move", true)


func _on_player_re_released(id):
	if(Lobby.player_info[id].obj == null):
		Game.add_player(id)
		Game.refresh_playerlist()
	Game.Board.set_player_to_actual_position(Lobby.player_info[id].obj, Lobby.player_info[id].position)
	if(get_tree().is_network_server()):
		if(PlayerNow == NO_BODY_GO):
			_next_player()
		rpc_id(int(Lobby.player_ids[PlayerNow]), "_let_player_make_move", true)


func _on_players_started_discussion():
	bDiscussion = true


func _on_players_ended_discussion():
	bDiscussion = false
	rpc_id(int(_get_prev_player_id()), "_hide_new_card")
	rpc("_let_player_make_move", false)
	
	if (PlayerNow != NO_BODY_GO):
		rpc_id(int(Lobby.player_ids[PlayerNow]), "_let_player_make_move", true)


func _on_player_end_playing(playerid):
	Lobby.player_info[playerid].is_end_game = true
	Game.add_card_to_player(playerid)
	#rpc_id(playerid, "_player_stop_game")
	#_on_players_ended_discussion()


func _on_player_want_move():
	rpc("_player_want_to_move")


master func _on_started_trading_between_players(main_trader, type_tradeing):
	#Если на арене меньше двух игроков, то обмена не происходит
	if(Lobby.player_ids.size() < 2):
		return
	MainTraderId = main_trader
	rpc("_show_to_players_change_screen", true, main_trader, type_tradeing)


func _on_player_start_trade_card(card_name):
	rpc("_player_want_to_trade", card_name)

func _on_player_stop_trade_card():
	rpc("_player_dont_want_to_trade")


func _on_make_trade(ChooisedPlayerId):
	rpc("_player_maked_trade", ChooisedPlayerId)


func _on_player_want_to_set_pos(new_pos):
	rpc("_move_player_to_him_pos", new_pos)


func _on_player_disconnected(id):
	var DeletedPlayer: int = Lobby.player_ids.find(id)
	
	if(DeletedPlayer == -1 or (not get_tree().is_network_server())):	
		Game.refresh_playerlist()
		
		#Если происходит обмен и остаётся менее двух игроков или игру покидает MainTraider, то закрываем экран обмена
		if (Game.ChangeScreen.MainTraderId != 0):
			if (Lobby.player_info.size() < 2 or id == Game.ChangeScreen.MainTraderId):
				Game.show_change_screen_to_player(false, 0, 0)
		return

	Lobby.player_ids.erase(id)
	Game.refresh_playerlist()

	if(PlayerNow == DeletedPlayer):
		PlayerNow -= 1
		_next_player()
		bDiscussion = false
		if (Lobby.player_ids.size() > 0 and PlayerNow != NO_BODY_GO):
			rpc_id(int(Lobby.player_ids[PlayerNow]), "_let_player_make_move", true)
	elif(PlayerNow > DeletedPlayer):
		PlayerNow -= 1
		assert(PlayerNow >= 0)
		rpc_id(int(Lobby.player_ids[PlayerNow]), "_let_player_make_move", true)
