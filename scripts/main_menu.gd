extends Control

# Save select screen inputs
@onready var as_server_toggle: CheckButton = $Menus/WorldScreen/WorldSelect/Toggles/AsServer
@onready var allow_players_toggle: CheckButton = $Menus/WorldScreen/WorldSelect/Toggles/AllowPlayers

# Multiplayer select screen inputs
@onready var server_ip_box: LineEdit = $Menus/MultiplayerScreen/Multiplayer/HBoxContainer/IP
@onready var server_name_box: LineEdit = $Menus/MultiplayerScreen/Multiplayer/HBoxContainer/Name

func open_screen(screen_name: String):
	for child in $Menus.get_children():
		child.visible = false
	get_node("Menus/" + screen_name).visible = true

func start_game(is_hosting: bool = false) -> void:
	pass # Replace with function body.

func toggle_multiplayer_joining(value: bool):
	as_server_toggle.disabled = not value
	if not value:
		as_server_toggle.button_pressed = false

func quit():
	get_tree().quit()
