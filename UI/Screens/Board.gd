extends ScrollContainer

# Константа обозначающая сдвиг со старта в древе детей
const SHIFT_POSITON = 35

signal completed_move

onready var BoardFields = $Background

var PlayersTimer
# Первый элемент это актуальная позиция, второй элемент это позиция куда надо следовать.
var _moving_players = {}

func _ready():
	#var BoardPath = Utility.read_json_file("user://BoardPath.json")
	var BoardPath = Utility.read_json_file("res://Data/BoardPath.json")
	
	for i in range(SHIFT_POSITON, BoardFields.get_child_count()):
		var cell: Cell = BoardFields.get_child(i)
		
		cell.set_board_position(i-SHIFT_POSITON)
		cell.set_board_desc(BoardPath[i-SHIFT_POSITON]["name"])
		
		#print(cell.Position, ") type: ", cell.Type, ", desc:", cell.Description)
	
	PlayersTimer = Timer.new()
	PlayersTimer.connect("timeout",self,"_update_players_boards")
	PlayersTimer.wait_time = 0.2
	PlayersTimer.one_shot = false
	add_child(PlayersTimer)
	PlayersTimer.start()

func set_player_to_actual_position(player, position):
	#Проверяем не удалён ли объект игрока
	if (is_instance_valid(player) == false):
		return
	
	if(not player in _moving_players):
		_moving_players[player] = [position, position, false]

	if(player.get_parent() != null):
		player.get_parent().remove_child(player)
		
	var Place = BoardFields.get_child(position+SHIFT_POSITON).get_node("PlacePlayers")
	if(Place.get_child(0).get_child_count() < 2):
		Place.get_child(0).add_child(player)
	else:
		Place.get_child(1).add_child(player)

# Ожидает первым параметром ссылку на поле игрока. Второе номер по порядку в какое поле вставить
func set_player_to_board(player, position):
	if(not player in _moving_players):
		_moving_players[player] = [position-1, position, true]
	else:
		_moving_players[player][1] = position
		_moving_players[player][2] = true

func get_field(position):
	position += SHIFT_POSITON
	var max_pos = BoardFields.get_child_count() - 1;
	if (position > max_pos):
		position = max_pos
	return BoardFields.get_child(position)

func _update_players_boards():
	for player in _moving_players:
		if(_moving_players[player][0] != _moving_players[player][1]):
			if _moving_players[player][1] < _moving_players[player][0]:
				_moving_players[player][0] -= 1
			else:
				_moving_players[player][0] += 1
			set_player_to_actual_position(player, _moving_players[player][0])
		else:
			if(_moving_players[player][2] == true):
				_moving_players[player][2] = false
				#Проверяем не удалён ли объект игрока
				if (is_instance_valid(player)):
					if(int(player.name) == get_tree().get_network_unique_id()):
						emit_signal("completed_move")
			continue
