extends Control

# Worlds selection screen inputs
@onready var allow_multiplayer_joining_toggle: CheckButton = $Menus/WorldsScreen/WorldsScreenUI/Toggles/AllowJoining
@onready var host_without_playing_toggle: CheckButton = $Menus/WorldsScreen/WorldsScreenUI/Toggles/HostWithoutPlay

# Called when this script is loaded into the scene
func _ready() -> void:
	NetworkManager.network_status_update.connect(self.network_status_update)

# Called every frame
func _process(_delta: float) -> void:
	pass

# Display the current connecting status
func network_status_update(message: String, should_display: bool, show_back_button: bool):
	$Menus/NetworkInfoOverlay.visible = should_display
	$Menus/NetworkInfoOverlay/RichTextLabel.text = message
	$Menus/NetworkInfoOverlay/BackButton.visible = show_back_button

# Open one of the screens on the menu and close all others.
func open_menu(screen_name: String) -> void:
	for child in $Menus.get_children():
		child.visible = false
	get_node("Menus/" + screen_name).visible = true

# Host or join a game
func start_game(is_hosting: bool = false) -> void:
	if is_hosting:
		NetworkManager.start_game(not host_without_playing_toggle.button_pressed, true, allow_multiplayer_joining_toggle.button_pressed)
	else:
		NetworkManager.start_game(true, false, true, "127.0.0.1")

# Close the game.
func quit() -> void:
	get_tree().quit()
