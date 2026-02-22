@tool
extends EditorPlugin

var panel: Control
var panel_button: Button

func _enter_tree():
	print("═══════════════════════════════════════")
	print("TeboAI: _enter_tree() called")
	print("═══════════════════════════════════════")
	
	var scene_path = "res://addons/tebo_ai/scenes/chat_panel.tscn"
	print("TeboAI: Loading scene from: " + scene_path)
	
	if not ResourceLoader.exists(scene_path):
		push_error("TeboAI: Scene file not found: " + scene_path)
		return
	
	var scene = load(scene_path)
	if scene == null:
		push_error("TeboAI: Failed to load scene")
		return
	
	print("TeboAI: Scene loaded, instantiating...")
	panel = scene.instantiate()
	
	if panel == null:
		push_error("TeboAI: Failed to instantiate panel")
		return
	
	print("TeboAI: Panel created, adding to bottom panel...")
	panel_button = add_control_to_bottom_panel(panel, "TeboAI")
	
	print("TeboAI: Loading settings...")
	TeboAISettings.load_settings()
	
	print("TeboAI: Plugin initialized successfully!")

func _exit_tree():
	print("TeboAI: _exit_tree() called")
	if panel:
		remove_control_from_bottom_panel(panel)
		panel.queue_free()
	if panel_button:
		panel_button.queue_free()
