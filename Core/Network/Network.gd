extends Node

# Отправляется когда успешно создается сервер
signal on_created_server
# Отправляется когда успешно подключился к серверу
signal on_connected_to_server

# Хранит локальный IP к которому можно будет подключиться. Используется только для дебага
var device_ip

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")

	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") and not ip.ends_with("1."):
			device_ip = ip
	print(device_ip)

func create_server(port, amount_clients):
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(port, amount_clients)
	get_tree().set_network_peer(peer)
	
	randomize()
	emit_signal("on_created_server")

func connect_to_server(ip, port):
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, port)
	
	randomize()
	get_tree().set_network_peer(peer)

func _on_network_peer_connected(id):
	print("Player " + str(id) + " has connected")

func _on_network_peer_disconnected(id):
	print("Player " + str(id) + " has disconnected")
