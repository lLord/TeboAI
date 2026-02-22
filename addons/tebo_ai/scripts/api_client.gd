extends Node
class_name TeboAIClient

const SettingsScript = preload("res://addons/tebo_ai/scripts/settings.gd")
const ToolExecutorScript = preload("res://addons/tebo_ai/scripts/tool_executor.gd")

signal response_received(text: String)
signal error_received(error: String)
signal stream_chunk(text: String)
signal debug_log(message: String)
signal tool_executed(tool_name: String, success: bool, message: String)

var http: HTTPRequest
var settings
var messages: Array = []
var pending_tool_calls: Array = []
var max_tool_iterations: int = 5
var current_iteration: int = 0

func _init():
	print("TeboAI: APIClient _init() called")
	settings = SettingsScript.get_instance()

func set_http_request(hr: HTTPRequest):
	print("TeboAI: Setting up HTTPRequest")
	http = hr
	http.timeout = 180.0
	http.request_completed.connect(_on_http_completed)

func add_message(role: String, content: String, tool_calls: Array = []):
	var msg = {"role": role, "content": content}
	if role == "assistant" and tool_calls.size() > 0:
		msg["tool_calls"] = tool_calls
	messages.append(msg)

func add_tool_result(tool_call_id: String, tool_name: String, result: String):
	messages.append({
		"role": "tool",
		"tool_call_id": tool_call_id,
		"name": tool_name,
		"content": result
	})

func clear_messages():
	messages.clear()
	current_iteration = 0

func send_message(user_message: String, use_project_context: bool = true) -> bool:
	debug_log.emit("[DEBUG] send_message called")
	current_iteration = 0
	
	var requires_key = settings.get_provider_requires_key(settings.api_provider)
	debug_log.emit("[DEBUG] Provider requires key: " + str(requires_key))
	
	if requires_key and settings.api_key.is_empty():
		var err = "API key not configured. Please set it in TeboAI settings."
		error_received.emit(err)
		debug_log.emit("[ERROR] " + err)
		return false
	
	var context = ""
	if use_project_context:
		context = _get_project_context()
		if not context.is_empty():
			debug_log.emit("[DEBUG] Project context loaded (" + str(context.length()) + " chars)")
	
	add_message("user", user_message)
	
	return _send_request(context)

func _send_request(context: String = "") -> bool:
	current_iteration += 1
	debug_log.emit("[DEBUG] Sending request, iteration: " + str(current_iteration))
	
	if current_iteration > max_tool_iterations:
		debug_log.emit("[WARNING] Max tool iterations reached")
		response_received.emit("I've completed the requested operations. Let me know if you need anything else!")
		return true
	
	var system_content = settings.system_prompt
	if not context.is_empty():
		system_content += "\n\nCurrent project context:\n" + context
	
	var full_messages = [{"role": "system", "content": system_content}]
	full_messages.append_array(messages)
	
	debug_log.emit("[DEBUG] Total messages in request: " + str(full_messages.size()))
	
	var api_format = settings.get_provider_api_format(settings.api_provider)
	debug_log.emit("[DEBUG] API format: " + api_format)
	
	var body: Dictionary
	var url: String = settings.api_url
	
	if api_format == "anthropic":
		body = _build_anthropic_body(full_messages)
	else:
		body = _build_openai_body(full_messages)
	
	var headers = settings.get_provider_headers(settings.api_provider, settings.api_key)
	
	var json = JSON.new()
	var body_string = json.stringify(body)
	
	_log_request(url, headers, body_string)
	
	var err = http.request(url, headers, HTTPClient.METHOD_POST, body_string)
	if err != OK:
		var err_msg = "Failed to send HTTP request (error code: " + str(err) + ")"
		error_received.emit(err_msg)
		debug_log.emit("[ERROR] " + err_msg)
		return false
	
	debug_log.emit("[DEBUG] HTTP request sent successfully")
	return true

func _build_openai_body(full_messages: Array) -> Dictionary:
	var tools = ToolExecutorScript.get_tool_definitions()
	
	return {
		"model": settings.model,
		"messages": full_messages,
		"max_tokens": settings.max_tokens,
		"temperature": settings.temperature,
		"stream": false,
		"tools": tools,
		"tool_choice": "auto"
	}

func _build_anthropic_body(full_messages: Array) -> Dictionary:
	return {
		"model": settings.model,
		"messages": full_messages,
		"max_tokens": settings.max_tokens
	}

func _log_request(url: String, headers: Array, body: String):
	debug_log.emit("═══════════════════════════════════════")
	debug_log.emit("[REQUEST] " + Time.get_datetime_string_from_system())
	debug_log.emit("URL: " + url)
	debug_log.emit("─── HEADERS ───")
	for h in headers:
		var h_display = h
		if "Authorization" in h:
			var parts = h.split(": ", true, 1)
			if parts.size() == 2:
				var key_preview = parts[1].substr(0, 10) + "..." if parts[1].length() > 10 else parts[1]
				h_display = parts[0] + ": " + key_preview
		debug_log.emit("  " + h_display)
	debug_log.emit("─── BODY (truncated) ───")
	var body_pretty = _pretty_json(body)
	var lines = body_pretty.split("\n")
	var max_lines = mini(lines.size(), 30)
	for i in range(max_lines):
		debug_log.emit("  " + lines[i])
	if lines.size() > 30:
		debug_log.emit("  ... (" + str(lines.size() - 30) + " more lines)")

func _on_http_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	_log_response(result, response_code, headers, body)
	handle_response(result, response_code, headers, body)

func _log_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	debug_log.emit("─── RESPONSE ───")
	debug_log.emit("[RESPONSE] " + Time.get_datetime_string_from_system())
	debug_log.emit("Status: " + str(response_code) + " (Result: " + str(result) + ")")
	var body_text = body.get_string_from_utf8()
	debug_log.emit("[DEBUG] Body size: " + str(body_text.length()) + " chars")
	var body_pretty = _pretty_json(body_text)
	var lines = body_pretty.split("\n")
	var max_lines = mini(lines.size(), 20)
	for i in range(max_lines):
		debug_log.emit("  " + lines[i])
	if lines.size() > 20:
		debug_log.emit("  ... (" + str(lines.size() - 20) + " more lines)")
	debug_log.emit("═══════════════════════════════════════")

func _pretty_json(json_string: String) -> String:
	var json = JSON.new()
	if json.parse(json_string) == OK:
		return JSON.new().stringify(json.get_data(), "  ")
	return json_string

func handle_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	debug_log.emit("[DEBUG] Processing response...")
	
	if result != HTTPRequest.RESULT_SUCCESS:
		var err = "HTTP request failed (result code: " + str(result) + ")"
		error_received.emit(err)
		debug_log.emit("[ERROR] " + err)
		return
	
	var body_text = body.get_string_from_utf8()
	debug_log.emit("[DEBUG] Response body length: " + str(body_text.length()))
	
	if response_code != 200:
		var err = "API error " + str(response_code) + ": " + body_text
		error_received.emit(err)
		debug_log.emit("[ERROR] " + err)
		return
	
	var json = JSON.new()
	var parse_err = json.parse(body_text)
	if parse_err != OK:
		var err = "Failed to parse JSON response (error at line " + str(json.get_error_line()) + ")"
		error_received.emit(err)
		debug_log.emit("[ERROR] " + err)
		return
	
	var response = json.get_data()
	
	if not response is Dictionary:
		var err = "Invalid response format"
		error_received.emit(err)
		debug_log.emit("[ERROR] " + err)
		return
	
	debug_log.emit("[DEBUG] Response keys: " + str(response.keys()))
	
	if response.has("choices") and response["choices"] is Array and response["choices"].size() > 0:
		_process_openai_response(response)
	elif response.has("content") and response["content"] is Array:
		_process_anthropic_response(response)
	else:
		var err = "Unknown response format"
		error_received.emit(err)
		debug_log.emit("[ERROR] " + err)

func _process_openai_response(response: Dictionary):
	var choice = response["choices"][0]
	var message = choice.get("message", {})
	
	var content = message.get("content", "")
	var tool_calls = message.get("tool_calls", [])
	var finish_reason = choice.get("finish_reason", "")
	
	debug_log.emit("[DEBUG] finish_reason: " + finish_reason)
	debug_log.emit("[DEBUG] content length: " + str(content.length()))
	debug_log.emit("[DEBUG] tool_calls count: " + str(tool_calls.size()))
	
	if tool_calls.size() > 0:
		_handle_tool_calls(content, tool_calls)
	else:
		if not content.is_empty():
			add_message("assistant", content)
			response_received.emit(content)
			debug_log.emit("[SUCCESS] Response received (" + str(content.length()) + " chars)")
		else:
			response_received.emit("I've completed the requested operations.")
			debug_log.emit("[SUCCESS] Tool operations completed")

func _process_anthropic_response(response: Dictionary):
	var content_array = response.get("content", [])
	var text_content = ""
	
	for item in content_array:
		if item.get("type") == "text":
			text_content += item.get("text", "")
	
	if not text_content.is_empty():
		add_message("assistant", text_content)
		response_received.emit(text_content)
		debug_log.emit("[SUCCESS] Anthropic response received")
	else:
		error_received.emit("Empty response from Anthropic")

func _handle_tool_calls(content: String, tool_calls: Array):
	debug_log.emit("[INFO] Processing " + str(tool_calls.size()) + " tool calls...")
	
	if not content.is_empty():
		add_message("assistant", content, tool_calls)
	else:
		add_message("assistant", "", tool_calls)
	
	for tool_call in tool_calls:
		var tool_call_id = tool_call.get("id", "")
		var function_info = tool_call.get("function", {})
		var tool_name = function_info.get("name", "")
		var arguments_str = function_info.get("arguments", "{}")
		
		debug_log.emit("[TOOL] Executing: " + tool_name)
		debug_log.emit("[TOOL] Arguments: " + arguments_str)
		
		var json = JSON.new()
		var arguments = {}
		if json.parse(arguments_str) == OK:
			arguments = json.get_data()
		else:
			debug_log.emit("[ERROR] Failed to parse tool arguments")
			add_tool_result(tool_call_id, tool_name, "Error: Failed to parse arguments")
			continue
		
		var result = ToolExecutorScript.execute_tool(tool_name, arguments)
		
		var result_message = result.get("message", "")
		var success = result.get("success", false)
		
		tool_executed.emit(tool_name, success, result_message)
		debug_log.emit("[TOOL] Result: " + ("SUCCESS" if success else "FAILED") + " - " + result_message)
		
		var result_json = JSON.new().stringify({
			"success": success,
			"message": result_message,
			"data": result.get("data")
		})
		
		add_tool_result(tool_call_id, tool_name, result_json)
	
	debug_log.emit("[INFO] Tool calls completed, sending follow-up request...")
	
	call_deferred("_send_request_deferred")

func _send_request_deferred():
	_send_request("")

func _get_project_context() -> String:
	var context_parts = []
	
	var fs = EditorInterface.get_resource_filesystem()
	if fs:
		var file_list = _get_gdscript_files("res://")
		if file_list.size() > 0:
			context_parts.append("Project GDScript files:")
			for file_path in file_list.slice(0, 15):
				context_parts.append("  - " + file_path)
			if file_list.size() > 15:
				context_parts.append("  ... and " + str(file_list.size() - 15) + " more files")
	
	var current_script = EditorInterface.get_script_editor().get_current_script()
	if current_script:
		context_parts.append("\nCurrently open script: " + current_script.resource_path)
	
	return "\n".join(context_parts)

func _get_gdscript_files(path: String) -> Array:
	var files = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not file_name.begins_with("."):
				var full_path = path.path_join(file_name)
				if dir.current_is_dir():
					if not file_name in ["addons", ".godot"]:
						files.append_array(_get_gdscript_files(full_path))
				elif file_name.ends_with(".gd") or file_name.ends_with(".tscn"):
					files.append(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	return files
