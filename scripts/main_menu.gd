extends Control

# Save select screen inputs
@onready var as_server_toggle: CheckButton = $Menus/WorldScreen/WorldSelect/Toggles/AsServer
@onready var allow_players_toggle: CheckButton = $Menus/WorldScreen/WorldSelect/Toggles/AllowPlayers

# Multiplayer select screen inputs
@onready var server_ip_box: LineEdit = $Menus/MultiplayerScreen/Multiplayer/HBoxContainer/IP
@onready var server_name_box: LineEdit = $Menus/MultiplayerScreen/Multiplayer/HBoxContainer/Name

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
