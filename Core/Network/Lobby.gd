extends Node

signal on_player_released(id)
signal on_player_re_released(id)

# Информация о игроке
var my_player_info = {
	name = "",				# - имя игрока;
	obj = null,				# - ссылка на объект игрока в игре;
	cards = [],				# - карты;
	position = -1,			# - позиция на доске;
	amount_moves = 0,		# - количество ходов за секцию;
	position_list = 0,		# - позиция каким подключился игрок
	start_section = -1,
	is_end_game = false		# - закончил ли игрок игру
}

# Список информации о игроках
var player_info = {}

# Массив ID игроков по порядку их подключения. Хранится только на сервере
master var player_ids = []

# Список предложений от всех игроков. Должен быть везде одинаков. 
# Содержит ключ в виде id игрока и значение в виде названии карты, которую хочет заменить
var player_trade_lots = {}

# Начальная секция игры
var start_section = -1


func _ready():
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("network_peer_disconnected", self, "_on_disconnected_from_server")


# Создает игрока на сервере и передает всем
master func _register_player(info):
	var id = get_tree().get_rpc_sender_id()

	player_ids.append(id)

	for playerid in player_info:
		var player = player_info[playerid]

		if player.name == info.name:
			player_info[id] = player
			player_info.erase(playerid)
			rpc("_release_player", id, player_info[id], start_section)
			return

	player_info[id] = info
	player_info[id].position_list = len(player_ids) - 1
	rpc("_release_player", id, info, start_section)


remote func _on_unregister_player(id):
	if(player_info.has(id) and player_info[id].obj != null):
		player_info[id].obj.queue_free()

		if (not get_tree().is_network_server()):
			player_info.erase(id)


# Запрашивает информацию о всех игроках у сервера
master func _get_info_all_players():
	rpc_id(get_tree().get_rpc_sender_id(), "_release_all_players", player_info)


# Записывате игрок обратно в существующиего плеера
remote func _re_release_player(id, info, start_sec):
	player_info[id] = info
	start_section = start_sec
	emit_signal("on_player_re_released", id)


# Записывает игрока в общий список игроков
remotesync func _release_player(id, info, start_sec):
	player_info[id] = info
	start_section = start_sec
	emit_signal("on_player_released", id)


remote func _release_all_players(players_info):
	for ply in players_info:
		if ply == get_tree().get_network_unique_id():
			continue

		_release_player(ply, players_info[ply], start_section)


# Подключился игрок. Игрок регистрируется и получает информацию о всех игроках
func _on_connected_to_server():
	rpc("_register_player", my_player_info)
	rpc("_get_info_all_players")


# Игрок отключается от сервера
func _on_disconnected_from_server(id):
	print("Player " + str(id) + " has disconnected")
	rpc("_on_unregister_player", id)
