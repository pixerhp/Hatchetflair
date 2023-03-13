extends Control

# Save select screen inputs
@onready var as_server_toggle: CheckButton = $Menus/WorldScreen/WorldSelect/Toggles/AsServer
@onready var allow_players_toggle: CheckButton = $Menus/WorldScreen/WorldSelect/Toggles/AllowPlayers

# Multiplayer select screen inputs
@onready var server_ip_box: LineEdit = $Menus/MultiplayerScreen/Multiplayer/HBoxContainer/IP
@onready var server_name_box: LineEdit = $Menus/MultiplayerScreen/Multiplayer/HBoxContainer/Name

# Called when script is loaded into scene.
func _ready() -> void:
	NetworkManager.network_status_update.connect(self.network_status_update)

# Called every frame
func _process(_delta: float) -> void:
	# Code to handle some shortcuts to quickly start the game for testing.
	if Input.is_action_just_pressed("QuickstartGame"):
		as_server_toggle.button_pressed = false
		allow_players_toggle.button_pressed = true
		start_game(true)
	if Input.is_action_just_pressed("QuickJoinLocalhost"):
		server_ip_box.text = "127.0.0.1"
		start_game(false)

# Display the current connecting status.
func network_status_update(message: String, should_display: bool, show_back_button: bool):
	$Menus/NetworkInfoOverlay.visible = should_display
	$Menus/NetworkInfoOverlay/RichTextLabel.text = message
	$Menus/NetworkInfoOverlay/BackButton.visible = show_back_button

# Open one of the screens on the menu and close all others.
func open_screen(screen_name: String) -> void:
	for child in $Menus.get_children():
		child.visible = false
	get_node("Menus/" + screen_name).visible = true

# Host or join a game.
func start_game(is_hosting: bool = false) -> void:
	if is_hosting:
		NetworkManager.start_game(not as_server_toggle.button_pressed, true, allow_players_toggle.button_pressed)
	else:
		NetworkManager.start_game(true, false, true, server_ip_box.text)

# Disable the as_server_toggle if multiplaer joining is turned off.
func toggle_multiplayer_joining(value: bool) -> void:
	as_server_toggle.disabled = not value
	if not value:
		as_server_toggle.button_pressed = false

# Close the game.
func quit() -> void:
	get_tree().quit()
