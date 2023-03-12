extends Control

# Save select screen inputs
@onready var as_server_toggle: CheckButton = $Menus/SaveSelectScreen/SaveSelect/Toggles/AsServer
@onready var allow_players_toggle: CheckButton = $Menus/SaveSelectScreen/SaveSelect/Toggles/AllowPlayers

# Multiplayer select screen inputs
@onready var server_ip_box: LineEdit = $Menus/MultiplayerScreen/Multiplayer/IP
@onready var server_name_box: LineEdit = $Menus/MultiplayerScreen/Multiplayer/Name

func open_screen(screen_name: String):
	for child in $Menus.get_children():
		child.visible = false
	get_node("Menus/" + screen_name).visible = true

func start_game(is_hosting: bool = false) -> void:
	pass # Replace with function body.

func quit():
	get_tree().quit()
