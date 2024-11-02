extends Control



const Game = preload("../Screens/Game.gd")



onready var VChatContainer = $VChatContainer
onready var ChatRichLabel = $VChatContainer/ChatRichLabel
onready var MessageLineBox = $VChatContainer/MessageLineBox
onready var MessageLineEdit = $VChatContainer/MessageLineBox/MessageLineEdit


var IsSizeChanging = false
var IsPositionChanging = false


func _ready():
	Lobby.connect("on_player_released", self, "_on_player_released")
	#get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	#if (GameInst == null):
	#	return
	
	#GameInst.connect("add_card_to_player_CLIENT", self, "_add_card_to_player_CLIENT")
	

remote func _add_card_to_player_CLIENT(id, card):
	append_to_chat("Получена карта")

# Вызывается каждый тик
func _process(delta):
	change_chat_size()
	change_chat_position()


# Функция изменения размера чата
# Устроена таким образом, что окно нельзя увеличить за пределы корневого элемента (Chat)
# Функция подразумевает, что окно растягивается только вверх и вправо
func change_chat_size():
	if (IsSizeChanging):
		var newX = get_local_mouse_position().x
		var newY = get_local_mouse_position().y
		
		# Проверяем не находится новый размер правее области корневого элемента
		if (newX < rect_size.x):
			# Присваеваем новый размер, исключая влияние позиции чата на экране
			VChatContainer.rect_size.x = newX - VChatContainer.rect_position.x
		else:
			# Присваеваем максимально допустимый горизонтальный размер
			VChatContainer.rect_size.x = rect_size.x - VChatContainer.rect_position.x
			
		#if (get_global_mouse_position().y > 0):
		# Проверяем не находится новый размер выше области корневого элемента
		if (newY > rect_position.y):
			if (newY + VChatContainer.rect_min_size.y < rect_size.y):
				# Присваеваем новый размер, модифицируя margin_top, чтобы окно растягивалось вверх
				VChatContainer.margin_top = newY
		else:
			# Присваеваем максимально допустимый вертикальный размер
			VChatContainer.margin_top = 0


# Переменная, хранящая оффсет от VChatContainer.rect_position до той области, где была зажата кнопка,
# чтобы перемещать окно по оффсету, создавая иллюзию, что окно "перетаскивается", а не просто встаёт на позицию курсора
var click_offset : Vector2

# Функция изменения позиции чата
# Устроена таким образом, что окно нельзя переместить за пределы корневого элемента (Chat)
func change_chat_position():
	if (IsPositionChanging):
		var newX = get_global_mouse_position().x - click_offset.x
		var newY = get_global_mouse_position().y - click_offset.y
		
		# Проверяем не находится новая координата левее области корневого элемента
		if (newX >= rect_position.x):
			# Проверяем не находится новая координата правее области корневого элемента
			if (newX + VChatContainer.rect_size.x < rect_size.x):
				# Присваеваем новую позицию
				VChatContainer.rect_position.x = newX
			else:
				# Присваиваем максимально допустимую правую позицию
				VChatContainer.rect_position.x = rect_size.x - VChatContainer.rect_size.x
		# Присваиваем максимально допустимую левую позицию
		else:
			VChatContainer.rect_position.x = rect_position.x
			
		# Проверяем не находится новая координата выше области корневого элемента
		if (newY > rect_position.y):
			# Проверяем не находится новая координата ниже области корневого элемента
			if (newY + VChatContainer.rect_size.y < rect_size.y):
				VChatContainer.rect_position.y = newY
			else:
				# Присваиваем максимально допустимую низкую позицию
				VChatContainer.rect_position.y = rect_size.y - VChatContainer.rect_size.y
		else:
			# Присваиваем максимально допустимую высокую позицию
			VChatContainer.rect_position.y = rect_position.y


# Угловая кнопка для изменения размера
func _on_ResizeButton_gui_input(event):
	if (event is InputEventMouseButton and event.button_index == BUTTON_LEFT):
		if (event.pressed):
			IsSizeChanging = true
		else:
			IsSizeChanging = false
	

# Верхняя панель для перемещения чата
func _on_MovePanel_gui_input(event):
		if (event is InputEventMouseButton and event.button_index == BUTTON_LEFT):
			if (event.pressed):
				# Измеряем оффсет в момент зажатия кнопки
				click_offset = get_local_mouse_position() - VChatContainer.rect_position
				IsPositionChanging = true
			else:
				IsPositionChanging = false


# Нажатие MinimizeButton
func _on_MinimizeButton_pressed():
	if (ChatRichLabel.visible):
		ChatRichLabel.hide()
		MessageLineBox.hide()
	else:
		ChatRichLabel.show()
		MessageLineBox.show()
	


# Нажат Enter при вводе текста в MessageLine
func _on_MessageLineEdit_text_entered(new_text):
	if not new_text.empty():
		parse_message(new_text)
		MessageLineEdit.text = ""


# Нажата кнопка SendButton
func _on_SendButton_pressed():
	if not MessageLineEdit.text.empty():
		parse_message(MessageLineEdit.text)
		MessageLineEdit.text = ""


func parse_message(message : String):
	if (message.begins_with("/")):
		parse_command(message.trim_prefix("/"))
	else:
		send_msg(message)

# Для куратора айди будет равным нулю
const CURATOR_ID = 0

# Парсит команду
func parse_command(command : String):
	if command.begins_with("help") :
		parse_command_help()
	elif command.begins_with("msg") :
		parse_command_msg(command.trim_prefix("msg "))
	elif command.begins_with("curator") :
		parse_command_curator(command.trim_prefix("curator "))
	elif command.begins_with("clear") :
		parse_command_clear()
	else:
		append_to_chat("Неизвестная команда.")


func parse_command_help():
	var HELP_MSG = "[color=#b1c2ff]Чат[/color] представляет собой внутриигровое окно, предоставляющее возможность "
	HELP_MSG += "обмена текстовой информацией между игроками.\n"
	HELP_MSG += "Для отправки сообщения в общий чат достаточно ввести его в поле для ввода сообщения.\n"
	HELP_MSG += "Ввод команд начинается со знака \"/\". Список команд:\n"
	HELP_MSG += "[color=#b1c2ff]/help[/color] - Вывод справки.\n"
	HELP_MSG += "[color=#b1c2ff]/msg [/color][color=#d7e9ff]{никнейм} {сообщение}[/color] - Отправка другому игроку личного сообщения.\n"
	HELP_MSG += "[color=#b1c2ff]/curator [/color][color=#d7e9ff]{сообщение}[/color] - Отправка личного сообщения куратору.\n"
	HELP_MSG += "[color=#b1c2ff]/clear[/color] - Полная очистка чата.\n"
	HELP_MSG += "Окно чата является масштабируемым и перемещаемым. "
	HELP_MSG += "Для масштабирования зажмите и потяните верхний правый угол чата и придайте чату новый размер. "
	HELP_MSG += "Для перемещения чата зажмите и потяните титульную панель в новое место."
	HELP_MSG += "Чтобы свернуть или развернуть чат нажмите на кнопку \"-\"."
	append_to_chat(HELP_MSG)

func parse_command_clear():
	ChatRichLabel.bbcode_text = ""
	
func parse_command_curator(message : String):
	send_private_msg(CURATOR_ID, message)


func parse_command_msg(command : String):
	# Ищем игрока с нужным ником
	for player_id in Lobby.player_info:
		var Name = Lobby.player_info[player_id].name
		if command.begins_with(Name):
			# Если сервер, то дополнительно проверяем а сети ли игрок
			if (get_tree().is_network_server() and Lobby.player_ids.find(player_id) == -1):
				break
			
			send_private_msg(player_id, command.trim_prefix(Name + " "))
			return
	append_to_chat("Игрок не найден.")


func send_private_msg(player_id, message : String):
	if (get_tree().is_network_server()):
		send_private_msg_SERVER(player_id, CURATOR_ID, message)
	else:
		send_private_msg_CLIENT(player_id, message)


master func send_private_msg_SERVER(to_id, from_id, message : String):
	# Проверяем адресовано ли сообщение куратору или отправлено им.
	# Если да, то показываем сообщение на сервере, в ином случае - отправляем клиенту
	if (to_id == CURATOR_ID):
		handle_private_msg_CLIENT(to_id, from_id, message)
	else:
		rpc_id(to_id, "handle_private_msg_CLIENT", to_id, from_id, message)
	if (from_id == CURATOR_ID):
		handle_private_msg_CLIENT(to_id, from_id, message)
	else:
		rpc_id(from_id, "handle_private_msg_CLIENT", to_id, from_id, message)
	pass


func send_private_msg_CLIENT(player_id, message : String):
	rpc("handle_private_msg_SERVER", player_id, message)
	pass


remote func handle_private_msg_CLIENT(to_id, from_id, message : String):
	var format_msg = ""
	if (from_id == CURATOR_ID):
		format_msg += "[color=#ddaa47]Куратор[/color]"
	elif (from_id == get_tree().get_network_unique_id()):
		format_msg += "[color=#ddaa47]Вы[/color]"
	else:
		var Name = Lobby.player_info[from_id].name
		var NameColor = Game.ColorsPlayer[Lobby.player_info[from_id].position_list]
		format_msg += "[color=" + NameColor + "]" + Name + "[/color]"
	
	format_msg += "->"
	
	if (to_id == CURATOR_ID):
		format_msg += "[color=#ddaa47]Куратор[/color]"
	elif (to_id == get_tree().get_network_unique_id()):
		format_msg += "[color=#ddaa47]Вы[/color]"
	else:
		var Name = Lobby.player_info[to_id].name
		var NameColor = Game.ColorsPlayer[Lobby.player_info[to_id].position_list]
		format_msg += "[color=" + NameColor + "]" + Name + "[/color]"
	
	format_msg += ": " + message
	append_to_chat(format_msg)


master func handle_private_msg_SERVER(player_id, message : String):
	# Получаем айди получателя и айди отправителя
	var msg_receiver_id = player_id
	var msg_sender_id = get_tree().get_rpc_sender_id()
	if (msg_receiver_id == -1):
		return
	# Отправляем сообщение игрокам
	send_private_msg_SERVER(msg_receiver_id, msg_sender_id, message)


func send_msg(message : String):
	if (get_tree().is_network_server()):
		send_msg_SERVER(message)
	else:
		send_msg_CLIENT(message)


# Отправляет сообщение от клиента серверу в общий чат
func send_msg_CLIENT(message : String):
	rpc("handle_msg_SERVER", message)


# Отправляет сообщение от сервера клиентам в общий чат
func send_msg_SERVER(message : String):
	rpc("handle_msg_CLIENT", CURATOR_ID, message)


# Обрабатывает полученное сообщение от клиента в общем чате
master func handle_msg_SERVER(message : String):
	var player_id = get_tree().get_rpc_sender_id()
	rpc("handle_msg_CLIENT", player_id, message)


# Форматирует полученное сообщение от сервера в общем чате
remotesync func handle_msg_CLIENT(player_id, message : String):
	var Name : String
	var NameColor : String
	if (player_id == CURATOR_ID):
		Name = "Куратор"
		NameColor = "#FFFFFF"
	else:
		Name = Lobby.player_info[player_id].name
		NameColor = Game.ColorsPlayer[Lobby.player_info[player_id].position_list]
		
	var format_msg = "[color=" + NameColor + "]" + Name + ": [/color]"
	format_msg += message
	append_to_chat(format_msg)


# Составляет сообщение о присоединившимся игроке
func _on_player_released(id):
	var Name = Lobby.player_info[id].name
	var NameColor = Game.ColorsPlayer[Lobby.player_info[id].position_list]
	
	var format_msg = "Игрок "
	format_msg += "[color=" + NameColor + "]" + Name + "[/color]"
	format_msg += " присоединился к игре!"
	append_to_chat(format_msg)
	
	
# Составляет сообщение о вышедшем игроке
func _on_player_disconnected(id):
	var Name = Lobby.player_info[id].name
	var NameColor = Game.ColorsPlayer[Lobby.player_info[id].position_list]
	
	var format_msg = "Игрок "
	format_msg += "[color=" + NameColor + "]" + Name + "[/color]"
	format_msg += " покинул игру."
	append_to_chat(format_msg)
	
	
# Составляет сообщение о игроке, который окончил игру
func _on_player_end_playing(id):
	var Name = Lobby.player_info[id].name
	var NameColor = Game.ColorsPlayer[Lobby.player_info[id].position_list]
	
	var format_msg = "Игрок "
	format_msg += "[color=" + NameColor + "]" + Name + "[/color]"
	format_msg += " закончил игру!"
	append_to_chat(format_msg)
	

# Составляет сообщение о совершённом обмене
func trade_cards_between_players(playerid1, playerid2):
	var Name1 = Lobby.player_info[playerid1].name
	var Name2 = Lobby.player_info[playerid2].name
	var NameColor1 = Game.ColorsPlayer[Lobby.player_info[playerid1].position_list]
	var NameColor2 = Game.ColorsPlayer[Lobby.player_info[playerid2].position_list]
	
	var format_msg = "Игрок "
	format_msg += "[color=" + NameColor1 + "]" + Name1 + "[/color]"
	format_msg += " обменялся картами с "
	format_msg += "[color=" + NameColor2 + "]" + Name2 + "[/color]"
	format_msg += "!"
	append_to_chat(format_msg)
	


# Добавляет отформатированное сообщение в новую строку чата
func append_to_chat(format_msg : String):
	ChatRichLabel.bbcode_text += format_msg
	ChatRichLabel.bbcode_text += "\n"
