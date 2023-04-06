extends Node

signal on_player_released(id)

# Информация о игроке
# name - имя игрока; obj - ссылка на объект игрока в игре; position - позиция на доске;
# cards - карты; amount_moves - количество ходов за секцию.
var my_player_info = {name = "", obj = null, position = 0, cards = [], amount_moves = 0, start_section = -1, is_end_game = false}
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

# Создает игрока на сервере и передает всем
master func _register_player(info):
	var id = get_tree().get_rpc_sender_id()
	player_info[id] = info
	player_ids.append(id)
	rpc("_release_player", id, info, start_section)

# Запрашивает информацию о всех игроках у сервера
master func _get_info_all_players():
	rpc_id(get_tree().get_rpc_sender_id(), "_release_all_players", player_info)

# Записывает игрока в общий список игроков
remotesync func _release_player(id, info, start_sec):
	player_info[id] = info
	start_section = start_sec
	emit_signal("on_player_released", id)

remote func _release_all_players(players):
	for ply in players:
		if ply == get_tree().get_network_unique_id():
			continue
		_release_player(ply, players[ply], start_section)

# Подключился игрок. Игрок регистрируется и получает информацию о всех игроках
func _on_connected_to_server():
	rpc("_register_player", my_player_info)
	rpc("_get_info_all_players")
