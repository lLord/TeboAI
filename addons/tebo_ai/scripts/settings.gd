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

You have access to powerful tools for directly modifying and analyzing projects. Use them proactively.

FILE OPERATIONS:
- create_file(path, content): Create scripts, scenes, or any file
- read_file(path): Read file content
- edit_file(path, old_text, new_text): Make targeted edits
- delete_file(path): Remove files
- list_files(extension): List project files
- search_in_files(query): Search across all files

GODOT ENGINE:
- get_godot_version: Get installed Godot version
- get_project_info: Detailed project structure analysis
- launch_editor: Open the Godot editor

SCENE MANAGEMENT:
- create_scene(path, root_type, root_name, script_path): Create new scenes
  - root_type: Node2D, Node3D, Control, CharacterBody2D, etc.
- add_node_to_scene(scene_path, node_type, node_name, parent, position): Add nodes
  - node_type: Sprite2D, CollisionShape2D, AnimatedSprite2D, Camera2D, etc.
- parse_scene(path): Get scene structure (nodes, connections, resources)
- get_current_scene: Info about the open scene in editor

RESOURCES:
- load_sprite(scene_path, node_name, texture_path): Load texture into Sprite2D
- list_textures: Find all image files
- list_audio: Find all audio files

ADVANCED:
- get_file_uid(path): Get UID for Godot 4.4+ projects
- get_autoloads: List all singleton/autoload configurations

IMPORTANT RULES:
1. Use tools immediately when asked to create/modify - don't just show code
2. Always use res:// paths or relative paths (scripts/player.gd)
3. Use Godot 4.x syntax (@export, @onready, class_name, etc.)
4. When creating scenes, use create_scene then add_node_to_scene for children
5. For modifications, read_file first to understand current code
6. After changes, briefly explain what you did

Be helpful, concise, and create working code."

var providers: Array = []
var settings_defaults: Dictionary = {}

static var instance: TeboAISettings

static func get_instance() -> TeboAISettings:
	if not instance:
		instance = TeboAISettings.new()
		instance.load_models_config()
		instance._load_from_file()
	return instance

func _load_from_file():
	var config = ConfigFile.new()
	
	print("TeboAI: Loading settings from " + SETTINGS_PATH)
	
	if config.load(SETTINGS_PATH) == OK:
		print("TeboAI: Config file loaded successfully")
		api_provider = config.get_value("api", "provider", api_provider)
		api_key = config.get_value("api", "api_key", api_key)
		api_url = config.get_value("api", "api_url", api_url)
		model = config.get_value("api", "model", model)
		max_tokens = config.get_value("api", "max_tokens", max_tokens)
		temperature = config.get_value("api", "temperature", temperature)
		system_prompt = config.get_value("api", "system_prompt", system_prompt)
		
		print("TeboAI: Loaded provider=" + api_provider + " model=" + model)
	else:
		print("TeboAI: No config file found, using defaults")

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
	
	if providers.size() > 0 and api_provider.is_empty():
		var first_provider = providers[0]
		api_provider = first_provider.get("id", "")
		print("TeboAI: Setting default provider to: " + api_provider)
	
	if api_url.is_empty():
		var provider = get_provider_by_id(api_provider)
		if not provider.is_empty():
			api_url = provider.get("url", "")
			print("TeboAI: Setting URL from provider: " + api_url)
	
	if model.is_empty():
		var models = get_provider_models(api_provider)
		if models.size() > 0:
			model = models[0].get("id", "")
			print("TeboAI: Setting default model to: " + model)

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
	
	var err = config.save(SETTINGS_PATH)
	if err == OK:
		print("TeboAI: Settings saved to " + SETTINGS_PATH)
		print("TeboAI: Saved provider=" + api_provider + " model=" + model)
	else:
		push_error("TeboAI: Failed to save settings: " + str(err))

static func load_settings():
	get_instance()
	print("TeboAI: load_settings() called - instance ready")
