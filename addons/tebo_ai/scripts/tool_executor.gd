extends RefCounted
class_name TeboAIToolExecutor

const ProjectOpsScript = preload("res://addons/tebo_ai/scripts/project_ops.gd")
const GodotOpsScript = preload("res://addons/tebo_ai/scripts/godot_ops.gd")

static func get_tool_definitions() -> Array:
	return [
		{
			"type": "function",
			"function": {
				"name": "create_file",
				"description": "Create a new file or overwrite an existing file in the project",
				"parameters": {
					"type": "object",
					"properties": {
						"path": {"type": "string", "description": "File path relative to res://"},
						"content": {"type": "string", "description": "Full content to write"}
					},
					"required": ["path", "content"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "read_file",
				"description": "Read the content of a file in the project",
				"parameters": {
					"type": "object",
					"properties": {
						"path": {"type": "string", "description": "File path relative to res://"}
					},
					"required": ["path"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "edit_file",
				"description": "Edit an existing file by replacing specific text",
				"parameters": {
					"type": "object",
					"properties": {
						"path": {"type": "string", "description": "File path relative to res://"},
						"old_text": {"type": "string", "description": "Exact text to find and replace"},
						"new_text": {"type": "string", "description": "New text to replace with"}
					},
					"required": ["path", "old_text", "new_text"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "delete_file",
				"description": "Delete a file from the project",
				"parameters": {
					"type": "object",
					"properties": {
						"path": {"type": "string", "description": "File path relative to res://"}
					},
					"required": ["path"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "list_files",
				"description": "List all files in the project, optionally filtered by extension",
				"parameters": {
					"type": "object",
					"properties": {
						"extension": {"type": "string", "description": "Optional extension filter (e.g., '.gd', '.tscn')"}
					},
					"required": []
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "search_in_files",
				"description": "Search for text across all project files",
				"parameters": {
					"type": "object",
					"properties": {
						"query": {"type": "string", "description": "Text to search for"}
					},
					"required": ["query"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "get_godot_version",
				"description": "Get the installed Godot engine version",
				"parameters": {"type": "object", "properties": {}, "required": []}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "get_project_info",
				"description": "Get detailed information about the project structure",
				"parameters": {"type": "object", "properties": {}, "required": []}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "launch_editor",
				"description": "Launch the Godot editor for the current project",
				"parameters": {"type": "object", "properties": {}, "required": []}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "create_scene",
				"description": "Create a new Godot scene with a root node",
				"parameters": {
					"type": "object",
					"properties": {
						"path": {"type": "string", "description": "Path for the new scene (e.g., 'scenes/player.tscn')"},
						"root_type": {"type": "string", "description": "Type of root node (e.g., 'Node2D', 'Node3D', 'Control')"},
						"root_name": {"type": "string", "description": "Name for the root node"},
						"script_path": {"type": "string", "description": "Optional script to attach to root node"}
					},
					"required": ["path", "root_type", "root_name"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "add_node_to_scene",
				"description": "Add a node to an existing scene",
				"parameters": {
					"type": "object",
					"properties": {
						"scene_path": {"type": "string", "description": "Path to the scene file"},
						"node_type": {"type": "string", "description": "Type of node to add (e.g., 'Sprite2D', 'CollisionShape2D')"},
						"node_name": {"type": "string", "description": "Name for the new node"},
						"parent": {"type": "string", "description": "Parent path (e.g., '.' for root, 'Player/Sprite')"},
						"position": {"type": "string", "description": "Optional position as 'x, y'"}
					},
					"required": ["scene_path", "node_type", "node_name"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "parse_scene",
				"description": "Parse a scene file and return its structure",
				"parameters": {
					"type": "object",
					"properties": {
						"path": {"type": "string", "description": "Path to the scene file"}
					},
					"required": ["path"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "load_sprite",
				"description": "Load a texture/sprite into a Sprite2D node in a scene",
				"parameters": {
					"type": "object",
					"properties": {
						"scene_path": {"type": "string", "description": "Path to the scene file"},
						"node_name": {"type": "string", "description": "Name of the Sprite2D node"},
						"texture_path": {"type": "string", "description": "Path to the texture file"}
					},
					"required": ["scene_path", "node_name", "texture_path"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "get_file_uid",
				"description": "Get the UID of a file in Godot 4.4+",
				"parameters": {
					"type": "object",
					"properties": {
						"path": {"type": "string", "description": "Path to the file"}
					},
					"required": ["path"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "get_current_scene",
				"description": "Get information about the currently open scene in the editor",
				"parameters": {"type": "object", "properties": {}, "required": []}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "list_textures",
				"description": "List all texture/image files in the project",
				"parameters": {"type": "object", "properties": {}, "required": []}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "list_audio",
				"description": "List all audio files in the project",
				"parameters": {"type": "object", "properties": {}, "required": []}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "get_autoloads",
				"description": "Get all autoload/singletons configured in the project",
				"parameters": {"type": "object", "properties": {}, "required": []}
			}
		}
	]

static func execute_tool(tool_name: String, arguments: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "", "data": null}
	
	match tool_name:
		"create_file": result = _tool_create_file(arguments)
		"read_file": result = _tool_read_file(arguments)
		"edit_file": result = _tool_edit_file(arguments)
		"delete_file": result = _tool_delete_file(arguments)
		"list_files": result = _tool_list_files(arguments)
		"search_in_files": result = _tool_search_in_files(arguments)
		"get_godot_version": result = _tool_get_godot_version(arguments)
		"get_project_info": result = _tool_get_project_info(arguments)
		"launch_editor": result = _tool_launch_editor(arguments)
		"create_scene": result = _tool_create_scene(arguments)
		"add_node_to_scene": result = _tool_add_node_to_scene(arguments)
		"parse_scene": result = _tool_parse_scene(arguments)
		"load_sprite": result = _tool_load_sprite(arguments)
		"get_file_uid": result = _tool_get_file_uid(arguments)
		"get_current_scene": result = _tool_get_current_scene(arguments)
		"list_textures": result = _tool_list_textures(arguments)
		"list_audio": result = _tool_list_audio(arguments)
		"get_autoloads": result = _tool_get_autoloads(arguments)
		_: result.message = "Unknown tool: " + tool_name
	
	return result

static func _normalize_path(path: String) -> String:
	path = path.strip_edges()
	if path.begins_with("res://"):
		path = path.substr(6)
	elif path.begins_with("/"):
		path = path.substr(1)
	return "res://" + path

static func _tool_create_file(args: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "", "data": null}
	if not args.has("path") or not args.has("content"):
		result.message = "Missing required parameters: path and content"
		return result
	
	var path = _normalize_path(args.path)
	var dir_path = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	
	var file_result = ProjectOpsScript.write_file(path, args.content)
	if file_result.success:
		EditorInterface.get_resource_filesystem().scan()
		result.success = true
		result.message = "Created: " + path
		result.data = {"path": path}
	else:
		result.message = "Failed: " + file_result.error
	return result

static func _tool_read_file(args: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "", "data": null}
	if not args.has("path"):
		result.message = "Missing path"
		return result
	
	var path = _normalize_path(args.path)
	var file_result = ProjectOpsScript.read_file(path)
	if file_result.success:
		result.success = true
		result.message = "Read: " + path
		result.data = {"path": path, "content": file_result.content}
	else:
		result.message = "Failed: " + file_result.error
	return result

static func _tool_edit_file(args: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "", "data": null}
	if not args.has("path") or not args.has("old_text") or not args.has("new_text"):
		result.message = "Missing required parameters"
		return result
	
	var path = _normalize_path(args.path)
	var file_result = ProjectOpsScript.read_file(path)
	if not file_result.success:
		result.message = "Failed to read: " + file_result.error
		return result
	
	if not args.old_text in file_result.content:
		result.message = "Text not found in file"
		return result
	
	var new_content = file_result.content.replace(args.old_text, args.new_text)
	var write_result = ProjectOpsScript.write_file(path, new_content)
	if write_result.success:
		EditorInterface.get_resource_filesystem().scan()
		result.success = true
		result.message = "Edited: " + path
		result.data = {"path": path}
	else:
		result.message = "Failed to write: " + write_result.error
	return result

static func _tool_delete_file(args: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "", "data": null}
	if not args.has("path"):
		result.message = "Missing path"
		return result
	
	var path = _normalize_path(args.path)
	if not FileAccess.file_exists(path):
		result.message = "File not found"
		return result
	
	var err = DirAccess.remove_absolute(path)
	if err == OK:
		EditorInterface.get_resource_filesystem().scan()
		result.success = true
		result.message = "Deleted: " + path
	else:
		result.message = "Failed: " + str(err)
	return result

static func _tool_list_files(args: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "", "data": null}
	var extension = args.get("extension", "")
	var filters = ["*.gd", "*.tscn", "*.tres"]
	if not extension.is_empty():
		if not extension.begins_with("*"):
			extension = "*" + extension
		filters = [extension]
	
	var files = ProjectOpsScript.get_project_files(filters)
	result.success = true
	result.message = "Found " + str(files.size()) + " files"
	result.data = {"files": files}
	return result

static func _tool_search_in_files(args: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "", "data": null}
	if not args.has("query"):
		result.message = "Missing query"
		return result
	
	var search_results = ProjectOpsScript.find_in_files(args.query)
	result.success = true
	result.message = "Found " + str(search_results.size()) + " matches"
	result.data = {"results": search_results}
	return result

static func _tool_get_godot_version(_args: Dictionary) -> Dictionary:
	var version_result = GodotOpsScript.get_godot_version()
	if version_result.success:
		return {"success": true, "message": "Godot " + version_result.version, "data": version_result}
	return {"success": false, "message": version_result.error, "data": null}

static func _tool_get_project_info(_args: Dictionary) -> Dictionary:
	var info = GodotOpsScript.get_project_info_detailed()
	return {"success": true, "message": "Project: " + info.project_name, "data": info}

static func _tool_launch_editor(_args: Dictionary) -> Dictionary:
	var launch_result = GodotOpsScript.launch_editor("res://")
	if launch_result.success:
		return {"success": true, "message": launch_result.message, "data": launch_result}
	return {"success": false, "message": launch_result.message, "data": null}

static func _tool_create_scene(args: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "", "data": null}
	if not args.has("path") or not args.has("root_type") or not args.has("root_name"):
		result.message = "Missing required parameters"
		return result
	
	var scene_result = GodotOpsScript.create_scene(args.root_type, args.root_name, args.get("script_path", ""))
	if not scene_result.success:
		return {"success": false, "message": scene_result.get("error", "Failed"), "data": null}
	
	var path = _normalize_path(args.path)
	var dir_path = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	
	var write_result = ProjectOpsScript.write_file(path, scene_result.content)
	if write_result.success:
		EditorInterface.get_resource_filesystem().scan()
		result.success = true
		result.message = "Scene created: " + path
		result.data = {"path": path}
	else:
		result.message = "Failed to save: " + write_result.error
	return result

static func _tool_add_node_to_scene(args: Dictionary) -> Dictionary:
	if not args.has("scene_path") or not args.has("node_type") or not args.has("node_name"):
		return {"success": false, "message": "Missing required parameters", "data": null}
	
	var properties = {}
	if args.has("position"):
		var pos_parts = args.position.split(",")
		if pos_parts.size() == 2:
			properties["position"] = Vector2(pos_parts[0].strip_edges().to_float(), pos_parts[1].strip_edges().to_float())
	
	var add_result = GodotOpsScript.add_node_to_scene(
		args.scene_path, args.node_type, args.node_name,
		args.get("parent", "."), properties
	)
	
	if add_result.success:
		EditorInterface.get_resource_filesystem().scan()
		return {"success": true, "message": add_result.message, "data": add_result}
	return {"success": false, "message": add_result.error, "data": null}

static func _tool_parse_scene(args: Dictionary) -> Dictionary:
	if not args.has("path"):
		return {"success": false, "message": "Missing path", "data": null}
	
	var parse_result = GodotOpsScript.parse_scene_file(_normalize_path(args.path))
	if parse_result.success:
		return {"success": true, "message": "Parsed " + args.path, "data": parse_result}
	return {"success": false, "message": parse_result.error, "data": null}

static func _tool_load_sprite(args: Dictionary) -> Dictionary:
	if not args.has("scene_path") or not args.has("node_name") or not args.has("texture_path"):
		return {"success": false, "message": "Missing required parameters", "data": null}
	
	var load_result = GodotOpsScript.load_sprite_to_node(args.scene_path, args.node_name, args.texture_path)
	if load_result.success:
		EditorInterface.get_resource_filesystem().scan()
		return {"success": true, "message": load_result.message, "data": load_result}
	return {"success": false, "message": load_result.error, "data": null}

static func _tool_get_file_uid(args: Dictionary) -> Dictionary:
	if not args.has("path"):
		return {"success": false, "message": "Missing path", "data": null}
	
	var uid_result = GodotOpsScript.get_file_uid(args.path)
	if uid_result.success:
		return {"success": true, "message": "UID: " + uid_result.uid, "data": uid_result}
	return {"success": false, "message": uid_result.error, "data": null}

static func _tool_get_current_scene(_args: Dictionary) -> Dictionary:
	var scene_result = GodotOpsScript.get_current_scene()
	if scene_result.success:
		return {"success": true, "message": "Scene: " + scene_result.name, "data": scene_result}
	return {"success": false, "message": scene_result.error, "data": null}

static func _tool_list_textures(_args: Dictionary) -> Dictionary:
	var files = ProjectOpsScript.get_project_files(["*.png", "*.jpg", "*.jpeg", "*.webp", "*.svg"])
	return {"success": true, "message": "Found " + str(files.size()) + " textures", "data": {"files": files}}

static func _tool_list_audio(_args: Dictionary) -> Dictionary:
	var files = ProjectOpsScript.get_project_files(["*.wav", "*.ogg", "*.mp3"])
	return {"success": true, "message": "Found " + str(files.size()) + " audio files", "data": {"files": files}}

static func _tool_get_autoloads(_args: Dictionary) -> Dictionary:
	var autoloads = GodotOpsScript.get_all_autoloads()
	return {"success": true, "message": "Found " + str(autoloads.size()) + " autoloads", "data": {"autoloads": autoloads}}
