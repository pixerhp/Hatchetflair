extends Control

# Worlds selection screen inputs
@onready var host_without_playing_toggle: CheckButton = $Menus/WorldsScreen/WorldsScreenUI/Toggles/HostWithoutPlay
@onready var allow_multiplayer_joining_toggle: CheckButton = $Menus/WorldsScreen/WorldsScreenUI/Toggles/AllowJoining

# Servers selection screen inputs
@onready var server_ip_box: LineEdit = $Menus/MultiplayerScreen/MultiplayerScreenUI/HBoxContainer/IP
@onready var server_name_box: LineEdit = $Menus/MultiplayerScreen/MultiplayerScreenUI/HBoxContainer/Name

# Called when this script is loaded into the scene
func _ready() -> void:
	NetworkManager.network_status_update.connect(self.network_status_update)

# Called every frame
func _process(_delta: float) -> void:
	# Code to handle some shortcuts to quickly start the game for testing.
	# As of typing this, the keys are F1 and F2.
	if Input.is_action_just_pressed("QuickstartGame"):
		host_without_playing_toggle.button_pressed = false
		allow_multiplayer_joining_toggle.button_pressed = true
		start_game(true)
	if Input.is_action_just_pressed("QuickJoinLocalhost"):
		server_ip_box.text = "127.0.0.1"
		start_game(false)

# Display the current connecting status
func network_status_update(message: String, should_display: bool, show_back_button: bool):
	$Menus/NetworkInfoOverlay.visible = should_display
	$Menus/NetworkInfoOverlay/RichTextLabel.text = message
	$Menus/NetworkInfoOverlay/BackButton.visible = show_back_button

# Open one of the screens on the menu and close all others.
func open_screen(screen_name: String) -> void:
	for child in $Menus.get_children():
		child.visible = false
	get_node("Menus/" + screen_name).visible = true

# Host or join a game
func start_game(is_hosting: bool = false) -> void:
	if is_hosting:
		NetworkManager.start_game(not host_without_playing_toggle.button_pressed, true, allow_multiplayer_joining_toggle.button_pressed)
	else:
		NetworkManager.start_game(true, false, true, server_ip_box.text)

# Disables the host_without_playing_toggle if multiplaer joining is turned off.
func toggle_multiplayer_joining(button_value: bool) -> void:
	host_without_playing_toggle.disabled = not button_value
	if not button_value:
		host_without_playing_toggle.button_pressed = false

# Close the game.
func quit() -> void:
	get_tree().quit()
