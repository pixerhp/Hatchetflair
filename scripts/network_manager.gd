extends Node

func start_game(is_player: bool, is_server: bool, allow_others: bool, ip_address: String = "") -> void:
	if is_server:
		start_server()
		if is_player:
			player_connected(multiplayer.get_unique_id())
		multiplayer.multiplayer_peer.refuse_new_connections = not allow_others
	else:
		start_client(ip_address)

func start_client(ip: String) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	multiplayer.connected_to_server.connect(self.connected_to_server)
	multiplayer.server_disconnected.connect(self.disconnected_from_server)
	multiplayer.connection_failed.connect(self.connection_failed)
	multiplayer.auth_callback = authenticate
	peer.create_client(ip, 1324)
	multiplayer.set_multiplayer_peer(peer)
	print("Client start")

func connected_to_server():
	print("Connected")

func disconnected_from_server():
	print("Disconnected from server")

func connection_failed():
	print("Connection failed")

func start_server() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	multiplayer.peer_connected.connect(self.player_connected)
	multiplayer.peer_disconnected.connect(self.player_disconnected)
	multiplayer.peer_authenticating.connect(self.peer_authenticating)
	multiplayer.auth_callback = authenticate
	peer.create_server(1324)
	multiplayer.set_multiplayer_peer(peer)
	
	print("Server started")

func peer_authenticating(id: int) -> void:
	print("Player %d is authenticating..."%id)
	multiplayer.send_auth(id, [0])

func player_connected(id: int) -> void:
	print("Player (" + str(id) + ") connected")

func player_disconnected(id: int) -> void:
	print("Player (" + str(id) + ") disconnected")

func authenticate(id: int, data: PackedByteArray) -> void:
	if id == 1:
		multiplayer.send_auth(id, [1, 3, 3, 7])
		multiplayer.complete_auth(id)
	else:
		if data[0] == 1 and data[1] == 3 and data[2] == 3 and data[3] == 7:
			multiplayer.complete_auth(id)
			print("Player %d passed authentication"%id)
