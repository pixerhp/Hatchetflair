extends Node3D


func switch_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/main_scenes/main_menu.tscn")

@onready var chunk_manager_node: Object = $ChunksManager


func _process(delta):
	# Toggle the pause menu if its associated key is pressed.
	# !!! [in the future, esc should also be able to close out of other things WITHOUT opening this menu.]
	if Input.is_action_just_pressed("escape_pausemenu") and not $SettingsMenu.visible:
		$PauseMenu.visible = not $PauseMenu.visible
	
	if Input.is_action_just_pressed("spec_hud"):
		print("(Toggling/altering your HUD is not yet implemented.)")
	
	if Input.is_action_just_pressed("debug_lag_spike"):
		var prev_fps := Engine.max_fps
		Engine.max_fps = 1
		await get_tree().create_timer(0.9, true, true, true).timeout
		Engine.max_fps = prev_fps
	
	# debug toggles:
	if Input.is_action_just_pressed("debug_info"):
		Globals.draw_debug_info_text = not Globals.draw_debug_info_text
		print("draw debug text toggled: ", "ON" if Globals.draw_debug_info_text else "OFF")
	if Input.is_action_just_pressed("debug_borders"):
		Globals.draw_debug_chunk_borders = not Globals.draw_debug_chunk_borders
		print("draw debug chunk borders toggled: ", "ON" if Globals.draw_debug_chunk_borders else "OFF")
	 
	
	
	if Globals.draw_debug_info_text:
		DebugDraw.add_text("(counted) fps: " + str(Performance.get_monitor(Performance.TIME_FPS)))
		DebugDraw.add_text("")
		DebugDraw.add_text("draw calls: " + str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		DebugDraw.add_text("total primatives: " + str(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		DebugDraw.add_text("render buffer mem used: " + String.humanize_size(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)))
		DebugDraw.add_text("render texture mem used: " + String.humanize_size(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)))
		DebugDraw.add_text("")
		DebugDraw.add_text("object count: " + str(Performance.get_monitor(Performance.OBJECT_COUNT)))
		DebugDraw.add_text("object resource count: " + str(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)))
		DebugDraw.add_text("object node count: " + str(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		DebugDraw.add_text("object orphan node count: " + str(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
		DebugDraw.add_text("")
		DebugDraw.add_text("static memory used: " + String.humanize_size(Performance.get_monitor(Performance.MEMORY_STATIC)))
		DebugDraw.add_text("max static memory: " + String.humanize_size(Performance.get_monitor(Performance.MEMORY_STATIC_MAX)))
	
	return



func _on_pausemenu_resumegameplay_pressed():
	# !!! Later, the game world may be actually paused by the pause-menu in singleplayer, unpause it here.
	$PauseMenu.visible = false
func _on_pausemenu_settings_pressed():
	$PauseMenu.visible = false
	$SettingsMenu.visible = true
	pass
func _on_pausemenu_toggleafk_pressed():
	pass
func _on_resetcharacter_pressed():
	pass
func _on_pausemenu_saveandquit_pressed():
	# Wait for the chunks manager to finish up its work, such as saving currently loaded chunks.
	await chunk_manager_node.chunks_manager_thread_ended
	
	switch_to_main_menu()


func _on_close_settings_menu():
	$SettingsMenu.visible = false
	$PauseMenu.visible = true
	pass # Replace with function body.
