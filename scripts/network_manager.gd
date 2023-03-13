extends Node

# Called from the menu to start a server or join a server.
func start_game(is_player: bool, is_server: bool, allow_others: bool, ip_address: String = "") -> void:
	if is_server:
		start_server()
		if is_player:
			# Spawn a player for the host.
			player_connected(multiplayer.get_unique_id())
		multiplayer.multiplayer_peer.refuse_new_connections = not allow_others
	else:
		start_client(ip_address)

###########################
# Client code
###########################

# Called when the client is starting.
func start_client(ip: String) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	# Setup signals and callbacks for client.
	multiplayer.connected_to_server.connect(self.connected_to_server)
	multiplayer.server_disconnected.connect(self.disconnected_from_server)
	multiplayer.connection_failed.connect(self.connection_failed)
	multiplayer.auth_callback = authenticate
	# Connect to the server.
	peer.create_client(ip, 1324)
	multiplayer.set_multiplayer_peer(peer)
	print("Client start")

# Called once authentication of this client is complete.
func connected_to_server():
	print("Connected")

# Called in any situation where the client is disconnected from the server.
func disconnected_from_server():
	print("Disconnected from server")

# Called upon failing to connect to the server.
func connection_failed():
	print("Connection failed")

###########################
# Server code
###########################

# Called when the server is starting.
func start_server() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	# Setup signals and callbacks for server.
	multiplayer.peer_connected.connect(self.player_connected)
	multiplayer.peer_disconnected.connect(self.player_disconnected)
	multiplayer.peer_authenticating.connect(self.peer_authenticating)
	multiplayer.auth_callback = authenticate
	# Create the server.
	peer.create_server(1324)
	multiplayer.set_multiplayer_peer(peer)
	print("Server started")

# Called when a client finishes authentication.
# Also called when the host wants a player to be spawned for itself.
func player_connected(id: int) -> void:
	print("Player (" + str(id) + ") connected")

# Called when a client disconnects.
func player_disconnected(id: int) -> void:
	print("Player (" + str(id) + ") disconnected")

###########################
# Authentication code
###########################

# Run on the server when a client starts the authentication process.
func peer_authenticating(id: int) -> void:
	print("Player %d is authenticating..."%id)
	# Ask the client to authenticate.
	multiplayer.send_auth(id, [0])

# Does the actual authenticating.
func authenticate(sender_id: int, data: PackedByteArray) -> void:
	if sender_id == 1: # If the sender_id is the server, then this is running as a client.
		# Send the verification code
		multiplayer.send_auth(sender_id, [1, 3, 3, 7])
		multiplayer.complete_auth(sender_id)
	else: # If the sender_id is not the server, then this is running as the server.
		# Check the incoming verification code.
		if data[0] == 1 and data[1] == 3 and data[2] == 3 and data[3] == 7:
			multiplayer.complete_auth(sender_id)
			print("Player %d passed authentication"%sender_id)
