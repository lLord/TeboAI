extends RefCounted
class_name TeboAISettings

const SETTINGS_PATH = "user://tebo_ai_settings.cfg"
const MODELS_PATH = "res://addons/tebo_ai/models.json"

var api_provider: String = "openai"
var api_key: String = ""
var api_url: String = ""
var model: String = ""
var max_tokens: int = 4096
var temperature: float = 0.7
var system_prompt: String = "You are TeboAI, an AI assistant specialized in Godot 4.x game development integrated into the Godot editor.

You have access to tools that allow you to directly modify the project. Use them proactively when the user asks you to create, modify, or read files.

AVAILABLE TOOLS:
- create_file(path, content): Create a new file or overwrite an existing one. ALWAYS use this when asked to create scripts, scenes, or any files.
- read_file(path): Read the content of an existing file to understand it before modifying.
- edit_file(path, old_text, new_text): Make targeted edits to existing files by replacing specific text.
- delete_file(path): Remove a file from the project.
- list_files(extension): List project files, optionally filtered by extension.
- search_in_files(query): Search for text across all project files.

IMPORTANT RULES:
1. When asked to create a script, scene, or any file, use create_file immediately - do not just show code.
2. When asked to modify existing code, first use read_file to see the current content, then use edit_file to make changes.
3. Always use res:// paths (e.g., 'scripts/player.gd', 'scenes/level1.tscn').
4. For GDScript, use Godot 4.x syntax (class_name, @export, @onready, etc.)
5. For scenes, output valid .tscn format.
6. After making file changes, briefly explain what you did.

Be helpful, concise, and create working code. Always prefer using tools over just displaying code."

var providers: Array = []
var settings_defaults: Dictionary = {}

static var instance: TeboAISettings

static func get_instance() -> TeboAISettings:
	if not instance:
		instance = TeboAISettings.new()
		instance.load_models_config()
	return instance

func load_models_config():
	print("TeboAI: Loading models config from: " + MODELS_PATH)
	
	var file = FileAccess.open(MODELS_PATH, FileAccess.READ)
	if not file:
		push_error("TeboAI: Could not load models.json from " + MODELS_PATH)
		push_error("TeboAI: FileAccess error: " + str(FileAccess.get_open_error()))
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	print("TeboAI: models.json loaded, size: " + str(json_text.length()) + " chars")
	
	var json = JSON.new()
	var err = json.parse(json_text)
	
	if err != OK:
		push_error("TeboAI: Could not parse models.json")
		push_error("TeboAI: JSON error at line " + str(json.get_error_line()) + ": " + json.get_error_message())
		return
	
	var data = json.get_data()
	providers = data.get("providers", [])
	settings_defaults = data.get("settings", {})
	
	print("TeboAI: Loaded " + str(providers.size()) + " providers")
	
	if providers.size() > 0:
		var first_provider = providers[0]
		if api_url.is_empty():
			api_url = first_provider.get("url", "")
		if model.is_empty() and first_provider.has("models"):
			var models = first_provider["models"]
			if models.size() > 0:
				model = models[0].get("id", "")

func get_provider_by_id(provider_id: String) -> Dictionary:
	for provider in providers:
		if provider.get("id") == provider_id:
			return provider
	return {}

func get_provider_models(provider_id: String) -> Array:
	var provider = get_provider_by_id(provider_id)
	return provider.get("models", [])

func get_provider_url(provider_id: String) -> String:
	var provider = get_provider_by_id(provider_id)
	return provider.get("url", "")

func get_provider_headers(provider_id: String, api_key_val: String) -> Array:
	var provider = get_provider_by_id(provider_id)
	var headers_dict = provider.get("headers", {})
	var headers = ["Content-Type: application/json"]
	
	for key in headers_dict:
		var value = str(headers_dict[key]).replace("{api_key}", api_key_val)
		headers.append(key + ": " + value)
	
	return headers

func get_provider_requires_key(provider_id: String) -> bool:
	var provider = get_provider_by_id(provider_id)
	return provider.get("requires_key", true)

func get_provider_api_format(provider_id: String) -> String:
	var provider = get_provider_by_id(provider_id)
	return provider.get("api_format", "openai")

func save_settings():
	var config = ConfigFile.new()
	config.set_value("api", "provider", api_provider)
	config.set_value("api", "api_key", api_key)
	config.set_value("api", "api_url", api_url)
	config.set_value("api", "model", model)
	config.set_value("api", "max_tokens", max_tokens)
	config.set_value("api", "temperature", temperature)
	config.set_value("api", "system_prompt", system_prompt)
	config.save(SETTINGS_PATH)

static func load_settings():
	var settings = get_instance()
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		settings.api_provider = config.get_value("api", "provider", settings.api_provider)
		settings.api_key = config.get_value("api", "api_key", settings.api_key)
		settings.api_url = config.get_value("api", "api_url", settings.api_url)
		settings.model = config.get_value("api", "model", settings.model)
		settings.max_tokens = config.get_value("api", "max_tokens", settings.max_tokens)
		settings.temperature = config.get_value("api", "temperature", settings.temperature)
		settings.system_prompt = config.get_value("api", "system_prompt", settings.system_prompt)
