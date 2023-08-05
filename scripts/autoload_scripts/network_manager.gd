extends Node

signal network_status_update(message: String, should_display: bool, show_back_button: bool)

# Called when script is loaded.
func _ready() -> void:
	# Setup signals and callbacks.
	multiplayer.connected_to_server.connect(self.connected_to_server)
	multiplayer.server_disconnected.connect(self.disconnected_from_server)
	multiplayer.connection_failed.connect(self.connection_failed)
	multiplayer.peer_authenticating.connect(self.peer_authenticating)
	multiplayer.peer_authentication_failed.connect(self.peer_authentication_failed)
	
	multiplayer.peer_connected.connect(self.player_connected)
	multiplayer.peer_disconnected.connect(self.player_disconnected)
	
	multiplayer.auth_callback = authenticate

# Called from the menu to start a server or join a server.
func start_game(is_player: bool, is_server: bool, allow_others: bool, ip_address: String = "") -> void:
	if is_server:
		start_server()
		network_status_update.emit("Server started.", true, false)
		if is_player:
			# Spawn a player for the host.
			player_connected(multiplayer.get_unique_id())
			network_status_update.emit("Playing world as host.", true, false)
		multiplayer.multiplayer_peer.refuse_new_connections = not allow_others
	else:
		start_client(ip_address)

###########################
# Client code
###########################

# Called when the client is starting.
func start_client(ip: String) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	# Connect to the server.
	peer.create_client(ip, 1324)
	multiplayer.set_multiplayer_peer(peer)
	print("Connecting to server...")
	network_status_update.emit("Connecting to server...", true, false)

# Called once authentication of this client is complete.
func connected_to_server():
	print("Connected to server.")
	network_status_update.emit("Connected to server.", true, false)

# Called in any situation where the client is disconnected from the server.
func disconnected_from_server():
	print("Disconnected from server.")
	network_status_update.emit("Disconnected from server.", true, true)

# Called upon failing to connect to the server.
func connection_failed():
	print("Connection to server failed.")
	network_status_update.emit("Connection to server failed.", true, true)

###########################
# Server code
###########################

# Called when the server is starting.
func start_server() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	# Create the server.
	peer.create_server(1324)
	multiplayer.set_multiplayer_peer(peer)
	print("Server started")

# Called when a client finishes authentication.
# Also called when the host wants a player to be spawned for itself.
func player_connected(id: int) -> void:
	# Cancel if not running on server.
	if multiplayer.get_unique_id() != 1:
		return
	print("Player (" + str(id) + ") connected")

# Called when a client disconnects.
func player_disconnected(id: int) -> void:
	# Cancel if not running on server.
	if multiplayer.get_unique_id() != 1:
		return
	print("Player (" + str(id) + ") disconnected")

###########################
# Authentication code
###########################

# Called on server and client when client tries to authenticate.
func peer_authenticating(sender_id: int) -> void:
	if sender_id == 1: # If the sender_id is the server, then this is running as a client.
		print("Starting authentication with server...")
		network_status_update.emit("Starting authentication with server...", true, false)
	else: # If the sender_id is not the server, then this is running as the server.
		print("Player %d is authenticating..."%sender_id)
		# Ask the client to authenticate.
		multiplayer.send_auth(sender_id, [0])

# Called on server and client when client fails to authenticate.
func peer_authentication_failed(sender_id: int) -> void:
	if sender_id == 1: # If the sender_id is the server, then this is running as a client.
		print("Failed to authenticate with server.")
		network_status_update.emit("Failed to authenticate with server.", true, true)
	else: # If the sender_id is not the server, then this is running as the server.
		print("Player %d failed to authenticate."%sender_id)

# Does the actual authenticating.
func authenticate(sender_id: int, data: PackedByteArray) -> void:
	if sender_id == 1: # If the sender_id is the server, then this is running as a client.
		# Send the verification code
		multiplayer.send_auth(sender_id, [13])
		multiplayer.complete_auth(sender_id)
	else: # If the sender_id is not the server, then this is running as the server.
		# Check the incoming verification code.
		if data[0] == 13:
			multiplayer.complete_auth(sender_id)
			print("Player %d passed authentication"%sender_id)
