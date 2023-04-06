extends Panel

signal on_start_trade_card(name_card)
signal on_stop_trade_card()
signal on_make_trade(ChooicedPlayerId)

onready var _player_lot_scene = preload("res://UI/Elements/PlayerLot.tscn")
onready var _choosingcard_scene = preload("res://UI/Elements/ChoosingCard.tscn")

onready var PlayerList = $PlayerListPanel/VBoxContainer
onready var CardsList = $CardsListPanel/ScrollContainer/GridContainer
onready var PlaceYourChoicedCard = $YourChoicedCardPanel
onready var OpponentChoicedCard = $OpponentChoicedCardPanel2
onready var IndicatorTrading = $IndicatorTrading

var name_card_for_trading = ""
var bTrading = false
var ChooicedPlayerId = 0
var MainTraderId = 0

func _ready():
	pass # Replace with function body.

func show_screen(bShow, main_trader, type_tradeing):
	if(bShow):
		MainTraderId = main_trader
		load_all_player_cards(get_tree().get_network_unique_id(), type_tradeing)
		show()
	else:
		for n in OpponentChoicedCard.get_children():
			OpponentChoicedCard.remove_child(n)
			n.queue_free()
		for n in PlaceYourChoicedCard.get_children():
			PlaceYourChoicedCard.remove_child(n)
			n.queue_free()
		for n in PlayerList.get_children():
			n.set_active(false)
		
		IndicatorTrading.texture = preload("res://Art/Sprites/Sprite_DisagreeLot.png")
		name_card_for_trading = ""
		ChooicedPlayerId = 0
		MainTraderId = 0
		bTrading = false
		hide()

func add_player(id):
	if(id == get_tree().get_network_unique_id()):
		return
	var lot = _player_lot_scene.instance()
	lot.name = str(id)
	lot.set_nickname(Lobby.player_info[id].name)
	lot.connect("on_player_lot_pressed", self, "_on_player_lot_pressed")
	PlayerList.add_child(lot)

func set_active_player(id, bActive):
	var pl = PlayerList.get_node(str(id))
	if(pl):
		pl.set_active(bActive)

func update_trades(playerid, card_name):
	if(ChooicedPlayerId == playerid):
		_set_opponent_card(Lobby.player_trade_lots[playerid])
	if(MainTraderId == playerid):
		if(MainTraderId != get_tree().get_network_unique_id()):
			_set_opponent_card(Lobby.player_trade_lots[playerid])

func load_all_player_cards(id, type_tradeing):
	for n in CardsList.get_children():
		CardsList.remove_child(n)
		n.queue_free()
	
	for card in Lobby.player_info[id].cards:
		if(type_tradeing == 0):
			var cardscene = _choosingcard_scene.instance()
			cardscene.set_name_card(card.Name)
			cardscene.connect("on_change_card_pressed", self, "_on_change_card_pressed")
			CardsList.add_child(cardscene)
		else:
			if(card.Type != -1):
				continue
			var cardscene = _choosingcard_scene.instance()
			cardscene.set_name_card(card.Name)
			cardscene.connect("on_change_card_pressed", self, "_on_change_card_pressed")
			CardsList.add_child(cardscene)

func _set_opponent_card(card_name):
	if(OpponentChoicedCard.get_child_count() == 0):
		var cardscene = _choosingcard_scene.instance()
		cardscene.set_name_card(card_name)
		cardscene.Clickable = false
		OpponentChoicedCard.add_child(cardscene)
	else:
		OpponentChoicedCard.get_child(0).set_name_card(card_name)

func _on_change_card_pressed(button):
	if(bTrading):
		return
	var cardscene = _choosingcard_scene.instance()
	name_card_for_trading = button.get_name_card()
	cardscene.set_name_card(name_card_for_trading)
	cardscene.Clickable = true
	for n in PlaceYourChoicedCard.get_children():
		PlaceYourChoicedCard.remove_child(n)
		n.queue_free()
	PlaceYourChoicedCard.add_child(cardscene)

func _on_player_lot_pressed(button):
	if(MainTraderId != get_tree().get_network_unique_id()):
		return
	ChooicedPlayerId = button.name
	_set_opponent_card(Lobby.player_trade_lots[int(button.name)])

func _on_ButtonStartTrade_pressed():
	if(len(name_card_for_trading) != 0):
		if(!bTrading):
			IndicatorTrading.texture = preload("res://Art/Sprites/Sprite_AgreeLot.png")
			emit_signal("on_start_trade_card", name_card_for_trading)
			bTrading = true
		else:
			IndicatorTrading.texture = preload("res://Art/Sprites/Sprite_DisagreeLot.png")
			emit_signal("on_stop_trade_card")
			bTrading = false


func _on_ButtonMakeTrade_pressed():
	if(MainTraderId != get_tree().get_network_unique_id() or int(ChooicedPlayerId) == 0):
		return
	emit_signal("on_make_trade", ChooicedPlayerId)
