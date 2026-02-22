@tool
extends VBoxContainer

const SettingsScript = preload("res://addons/tebo_ai/scripts/settings.gd")
const ClientScript = preload("res://addons/tebo_ai/scripts/api_client.gd")
const ToolsScript = preload("res://addons/tebo_ai/scripts/tools.gd")

var api_client
var http_request: HTTPRequest

var messages_container: VBoxContainer
var input_field: TextEdit
var send_btn: Button
var clear_btn: Button
var settings_btn: Button
var loading_label: Label
var settings_popup: PopupPanel
var current_provider_label: Label
var console_output: RichTextLabel
var clear_console_btn: Button
var copy_console_btn: Button
var provider_option: OptionButton
var provider_info: Label
var refresh_btn: Button
var api_key_input: LineEdit
var url_input: LineEdit
var model_option: OptionButton
var model_id_label: Label
var temp_slider: HSlider
var temp_value: Label
var system_prompt_input: TextEdit

var settings
var console_logs: Array = []

var status_icon: RichTextLabel
var status_label: Label
var animation_timer: Timer
var animation_dots: int = 0
var is_thinking: bool = false

func _init():
	print("TeboAI: chat_panel _init() called")

func _ready():
	print("TeboAI: chat_panel _ready() called")
	
	_find_nodes()
	_setup_animation_timer()
	
	settings = SettingsScript.get_instance()
	print("TeboAI: Settings instance obtained")
	
	http_request = HTTPRequest.new()
	add_child(http_request)
	print("TeboAI: HTTPRequest created")
	
	api_client = ClientScript.new()
	print("TeboAI: APIClient created")
	
	api_client.set_http_request(http_request)
	api_client.response_received.connect(_on_response_received)
	api_client.error_received.connect(_on_error_received)
	api_client.debug_log.connect(_on_debug_log)
	api_client.tool_executed.connect(_on_tool_executed)
	
	_setup_ui()
	_setup_settings()
	_update_current_provider_display()
	
	_add_system_message("Welcome to TeboAI! Configure your API settings to get started.")
	_add_system_message("Type /help to see available commands.")
	
	_log_console("[INFO] ═══════════════════════════════════════")
	_log_console("[INFO] TeboAI initialized successfully")
	_log_console("[INFO] ═══════════════════════════════════════")
	_log_console("[INFO] Provider: " + settings.api_provider)
	_log_console("[INFO] Model: " + settings.model)

func _find_nodes():
	print("TeboAI: Finding nodes...")
	
	messages_container = get_node_or_null("TabContainer/Chat/MessagesScroll/Messages")
	input_field = get_node_or_null("TabContainer/Chat/InputContainer/InputRow/InputField")
	send_btn = get_node_or_null("TabContainer/Chat/InputContainer/InputRow/SendBtn")
	clear_btn = get_node_or_null("Toolbar/ClearBtn")
	settings_btn = get_node_or_null("Toolbar/SettingsBtn")
	loading_label = get_node_or_null("LoadingLabel")
	settings_popup = get_node_or_null("SettingsPopup")
	current_provider_label = get_node_or_null("Toolbar/CurrentProviderLabel")
	console_output = get_node_or_null("TabContainer/Console/ConsoleScroll/ConsoleOutput")
	clear_console_btn = get_node_or_null("TabContainer/Console/ConsoleToolbar/ClearConsoleBtn")
	copy_console_btn = get_node_or_null("TabContainer/Console/ConsoleToolbar/CopyConsoleBtn")
	provider_option = get_node_or_null("SettingsPopup/SettingsContent/ProviderSection/ProviderRow/ProviderOption")
	provider_info = get_node_or_null("SettingsPopup/SettingsContent/ProviderSection/ProviderInfo")
	refresh_btn = get_node_or_null("SettingsPopup/SettingsContent/ProviderSection/ProviderRow/RefreshBtn")
	api_key_input = get_node_or_null("SettingsPopup/SettingsContent/ConnectionSection/ApiKeyRow/ApiKeyInput")
	url_input = get_node_or_null("SettingsPopup/SettingsContent/ConnectionSection/UrlRow/UrlInput")
	model_option = get_node_or_null("SettingsPopup/SettingsContent/ModelSection/ModelRow/ModelOption")
	model_id_label = get_node_or_null("SettingsPopup/SettingsContent/ModelSection/ModelIdLabel")
	temp_slider = get_node_or_null("SettingsPopup/SettingsContent/ParametersSection/TempRow/TempSlider")
	temp_value = get_node_or_null("SettingsPopup/SettingsContent/ParametersSection/TempRow/TempValue")
	system_prompt_input = get_node_or_null("SettingsPopup/SettingsContent/ParametersSection/SystemPromptInput")
	status_icon = get_node_or_null("StatusBar/StatusIcon")
	status_label = get_node_or_null("StatusBar/StatusLabel")
	
	var nodes = {
		"messages_container": messages_container,
		"input_field": input_field,
		"send_btn": send_btn,
		"console_output": console_output,
		"settings_popup": settings_popup
	}
	
	for name in nodes:
		if nodes[name] == null:
			push_error("TeboAI: Node '" + name + "' NOT FOUND!")
		else:
			print("TeboAI: Node '" + name + "' OK")

func _setup_animation_timer():
	animation_timer = Timer.new()
	animation_timer.wait_time = 0.4
	animation_timer.one_shot = false
	animation_timer.timeout.connect(_on_animation_tick)
	add_child(animation_timer)
	_set_status_ready()

func _on_animation_tick():
	if not is_thinking:
		return
	
	animation_dots = (animation_dots + 1) % 4
	var dots = ""
	for i in range(animation_dots):
		dots += "."
	
	if status_label:
		status_label.text = "Thinking" + dots
	if status_icon:
		status_icon.text = "[color=yellow]●[/color]"

func _set_status_thinking():
	is_thinking = true
	animation_dots = 0
	if animation_timer:
		animation_timer.start()
	if status_icon:
		status_icon.text = "[color=yellow]●[/color]"
	if status_label:
		status_label.text = "Thinking"

func _set_status_success():
	is_thinking = false
	if animation_timer:
		animation_timer.stop()
	if status_icon:
		status_icon.text = "[color=green]✓[/color]"
	if status_label:
		status_label.text = "Done"
	
	get_tree().create_timer(2.0).timeout.connect(_set_status_ready)

func _set_status_error():
	is_thinking = false
	if animation_timer:
		animation_timer.stop()
	if status_icon:
		status_icon.text = "[color=red]✗[/color]"
	if status_label:
		status_label.text = "Error"
	
	get_tree().create_timer(3.0).timeout.connect(_set_status_ready)

func _set_status_ready():
	is_thinking = false
	if animation_timer:
		animation_timer.stop()
	if status_icon:
		status_icon.text = "[color=gray]○[/color]"
	if status_label:
		status_label.text = "Ready"

func _setup_ui():
	if send_btn:
		send_btn.pressed.connect(_on_send_pressed)
		print("TeboAI: send_btn connected")
	else:
		push_error("TeboAI: send_btn is null!")
	
	if clear_btn:
		clear_btn.pressed.connect(_on_clear_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	
	if input_field:
		input_field.gui_input.connect(_on_input_gui_input)
	
	var save_btn = get_node_or_null("SettingsPopup/SettingsContent/ButtonsRow/SaveBtn")
	var cancel_btn = get_node_or_null("SettingsPopup/SettingsContent/ButtonsRow/CancelBtn")
	if save_btn:
		save_btn.pressed.connect(_on_save_settings)
	if cancel_btn:
		cancel_btn.pressed.connect(_on_cancel_settings)
	
	if temp_slider:
		temp_slider.value_changed.connect(_on_temp_changed)
	if provider_option:
		provider_option.item_selected.connect(_on_provider_selected)
	if model_option:
		model_option.item_selected.connect(_on_model_selected)
	if refresh_btn:
		refresh_btn.pressed.connect(_on_refresh_providers)
	
	if clear_console_btn:
		clear_console_btn.pressed.connect(_on_clear_console)
	if copy_console_btn:
		copy_console_btn.pressed.connect(_on_copy_console)
	
	_populate_providers()
	
	_log_console("[DEBUG] UI setup complete")

func _on_input_gui_input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		if not Input.is_key_pressed(KEY_SHIFT):
			get_viewport().set_input_as_handled()
			_on_send_pressed()

func _populate_providers():
	provider_option.clear()
	for i in range(settings.providers.size()):
		var provider = settings.providers[i]
		var name = provider.get("name", "Unknown")
		var is_local = not provider.get("requires_key", true)
		if is_local:
			name += " [Local]"
		provider_option.add_item(name, i)

func _populate_models(provider_idx: int):
	model_option.clear()
	if provider_idx < 0 or provider_idx >= settings.providers.size():
		return
	
	var provider = settings.providers[provider_idx]
	var models = provider.get("models", [])
	for i in range(models.size()):
		var model = models[i]
		model_option.add_item(model.get("name", model.get("id", "Unknown")), i)
	
	if models.size() > 0:
		_update_model_id_label(0)

func _update_model_id_label(model_idx: int):
	var provider_idx = provider_option.get_selected_id()
	if provider_idx < 0 or provider_idx >= settings.providers.size():
		model_id_label.text = "Model ID: -"
		return
	
	var provider = settings.providers[provider_idx]
	var models = provider.get("models", [])
	
	if model_idx >= 0 and model_idx < models.size():
		var model_id = models[model_idx].get("id", "-")
		model_id_label.text = "Model ID: " + model_id
	else:
		model_id_label.text = "Model ID: -"

func _update_provider_info(provider_idx: int):
	if provider_idx < 0 or provider_idx >= settings.providers.size():
		provider_info.text = "Select a provider to see details"
		return
	
	var provider = settings.providers[provider_idx]
	var info_parts = []
	
	var requires_key = provider.get("requires_key", true)
	if requires_key:
		info_parts.append("[color=orange]Requires API Key[/color]")
	else:
		info_parts.append("[color=green]No API Key required (Local)[/color]")
	
	var url = provider.get("url", "")
	if not url.is_empty():
		info_parts.append("Endpoint: " + url)
	
	var models = provider.get("models", [])
	info_parts.append("Available models: " + str(models.size()))
	
	provider_info.text = "\n".join(info_parts)

func _update_current_provider_display():
	var provider_name = "Not configured"
	var model_name = ""
	
	for provider in settings.providers:
		if provider.get("id") == settings.api_provider:
			provider_name = provider.get("name", settings.api_provider)
			var models = provider.get("models", [])
			for model in models:
				if model.get("id") == settings.model:
					model_name = model.get("name", settings.model)
					break
			break
	
	if model_name.is_empty():
		model_name = settings.model
	
	current_provider_label.text = "(" + provider_name + " / " + model_name + ")"

func _setup_settings():
	var provider_idx = 0
	for i in range(settings.providers.size()):
		if settings.providers[i].get("id") == settings.api_provider:
			provider_idx = i
			break
	
	provider_option.select(provider_idx)
	_populate_models(provider_idx)
	_update_provider_info(provider_idx)
	
	var models = settings.get_provider_models(settings.api_provider)
	var model_idx = 0
	for i in range(models.size()):
		if models[i].get("id") == settings.model:
			model_idx = i
			break
	model_option.select(model_idx)
	_update_model_id_label(model_idx)
	
	api_key_input.text = settings.api_key
	
	if settings.api_url.is_empty():
		var provider = settings.providers[provider_idx]
		url_input.text = provider.get("url", "")
	else:
		url_input.text = settings.api_url
	
	temp_slider.value = settings.temperature
	system_prompt_input.text = settings.system_prompt
	
	print("TeboAI: Settings UI updated - Provider: " + settings.api_provider + ", Model: " + settings.model)

func _on_provider_selected(idx: int):
	_populate_models(idx)
	_update_provider_info(idx)
	
	if idx < settings.providers.size():
		var provider = settings.providers[idx]
		url_input.text = provider.get("url", "")
		
		var requires_key = provider.get("requires_key", true)
		api_key_input.editable = requires_key
		if not requires_key:
			api_key_input.text = ""
			api_key_input.placeholder_text = "Not required (local)"
		else:
			api_key_input.placeholder_text = "Enter your API key"
		
		if provider.get("models", []).size() > 0:
			_update_model_id_label(0)

func _on_model_selected(idx: int):
	_update_model_id_label(idx)

func _on_refresh_providers():
	settings.load_models_config()
	_populate_providers()
	_setup_settings()
	_log_console("[INFO] Providers refreshed from models.json")

func _on_send_pressed():
	_log_console("[DEBUG] _on_send_pressed called")
	
	var text = input_field.text.strip_edges()
	_log_console("[DEBUG] Input text: '" + text + "' (length: " + str(text.length()) + ")")
	
	if text.is_empty():
		_log_console("[DEBUG] Text is empty, returning")
		return
	
	input_field.text = ""
	
	var cmd_result = ToolsScript.process_command(text)
	_log_console("[DEBUG] Is command: " + str(cmd_result.is_command))
	
	if cmd_result.is_command:
		_add_user_message(text)
		_add_system_message(cmd_result.output)
		_log_console("[COMMAND] " + text)
		return
	
	_add_user_message(text)
	set_ui_blocked(true)
	_set_status_thinking()
	_log_console("[INFO] Sending message to API...")
	_log_console("[USER] " + text)
	_log_console("[DEBUG] Provider: " + settings.api_provider)
	_log_console("[DEBUG] Model: " + settings.model)
	_log_console("[DEBUG] URL: " + settings.api_url)
	_log_console("[DEBUG] API Key set: " + str(not settings.api_key.is_empty()))
	
	api_client.add_message("user", text)
	var success = api_client.send_message(text)
	_log_console("[DEBUG] send_message returned: " + str(success))
	
	if not success:
		set_ui_blocked(false)
		_set_status_error()
		_log_console("[ERROR] Failed to send message")

func _on_response_received(text: String):
	set_ui_blocked(false)
	_set_status_success()
	_add_assistant_message(text)
	_log_console("[INFO] Response displayed in chat")

func _on_error_received(error: String):
	set_ui_blocked(false)
	_set_status_error()
	_add_system_message("[color=red]Error:[/color] " + error)
	_log_console("[ERROR] " + error)

func _on_debug_log(message: String):
	_log_console(message)

func _on_tool_executed(tool_name: String, success: bool, message: String):
	var icon = "✓" if success else "✗"
	var color = "[color=green]" if success else "[color=red]"
	_add_system_message(color + icon + " " + tool_name + ": " + message + "[/color]")
	_log_console("[TOOL] " + icon + " " + tool_name + " - " + message)

func _log_console(message: String):
	console_logs.append(message)
	var timestamp = Time.get_time_string_from_system()
	
	var color = "[color=white]"
	if "[ERROR]" in message:
		color = "[color=red]"
	elif "[SUCCESS]" in message:
		color = "[color=green]"
	elif "[REQUEST]" in message:
		color = "[color=cyan]"
	elif "[RESPONSE]" in message:
		color = "[color=yellow]"
	elif "[INFO]" in message:
		color = "[color=blue]"
	elif "[USER]" in message or "[COMMAND]" in message:
		color = "[color=magenta]"
	elif "[TOOL]" in message:
		color = "[color=orange]"
	elif "[DEBUG]" in message:
		color = "[color=gray]"
	
	if console_output:
		console_output.append_text(color + "[" + timestamp + "] " + message + "[/color]\n")
		console_output.scroll_to_line(console_output.get_line_count() - 1)
	else:
		push_warning("TeboAI: Console output not ready - " + message)

func _on_clear_console():
	console_output.text = ""
	console_logs.clear()
	_log_console("[INFO] Console cleared")

func _on_copy_console():
	var text = "\n".join(console_logs)
	DisplayServer.clipboard_set(text)
	_log_console("[INFO] Console copied to clipboard")

func _on_clear_pressed():
	for child in messages_container.get_children():
		child.queue_free()
	api_client.clear_messages()
	_add_system_message("Chat cleared.")
	_log_console("[INFO] Chat history cleared")

func _on_settings_pressed():
	_setup_settings()
	settings_popup.popup_centered()

func _on_temp_changed(value: float):
	temp_value.text = "%.1f" % value

func _on_save_settings():
	var provider_idx = provider_option.get_selected_id()
	var model_idx = model_option.get_selected_id()
	
	if provider_idx < settings.providers.size():
		var provider = settings.providers[provider_idx]
		settings.api_provider = provider.get("id", "")
		
		var models = provider.get("models", [])
		if model_idx < models.size():
			settings.model = models[model_idx].get("id", "")
	
	settings.api_key = api_key_input.text
	settings.api_url = url_input.text
	settings.temperature = temp_slider.value
	settings.system_prompt = system_prompt_input.text
	
	settings.save_settings()
	settings_popup.hide()
	
	_update_current_provider_display()
	
	_add_system_message("Settings saved!")
	_log_console("[INFO] Settings saved")
	_log_console("[INFO] Provider: " + settings.api_provider)
	_log_console("[INFO] Model: " + settings.model)
	_log_console("[INFO] URL: " + settings.api_url)

func _on_cancel_settings():
	settings_popup.hide()

func set_ui_blocked(blocked: bool):
	send_btn.disabled = blocked
	input_field.editable = not blocked
	loading_label.visible = blocked

func _add_message(text: String, type: String) -> VBoxContainer:
	if messages_container == null:
		push_error("TeboAI: messages_container is null!")
		return null
	
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.y = 30
	
	match type:
		"user":
			label.text = "[color=4A9EFF][b]You:[/b][/color]\n" + text
		"assistant":
			label.text = "[color=50C878][b]TeboAI:[/b][/color]\n" + _format_response(text)
		"system":
			label.text = "[color=888888][i]" + text + "[/i][/color]"
	
	container.add_child(label)
	messages_container.add_child(container)
	
	await get_tree().process_frame
	
	var scroll = get_node_or_null("TabContainer/Chat/MessagesScroll")
	if scroll:
		scroll.ensure_control_visible(container)
	
	return container

func _add_user_message(text: String):
	_add_message(text, "user")

func _add_assistant_message(text: String):
	_add_message(text, "assistant")

func _add_system_message(text: String):
	_add_message(text, "system")

func _format_response(text: String) -> String:
	text = text.replace("```gdscript", "[code][color=CYAN]")
	text = text.replace("```", "[/color][/code]")
	return text
