extends RefCounted
class_name TeboAIToolExecutor

const ProjectOpsScript = preload("res://addons/tebo_ai/scripts/project_ops.gd")

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
						"path": {
							"type": "string",
							"description": "The file path relative to res:// (e.g., 'scripts/player.gd' or 'scenes/level1.tscn')"
						},
						"content": {
							"type": "string",
							"description": "The full content to write to the file"
						}
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
						"path": {
							"type": "string",
							"description": "The file path relative to res://"
						}
					},
					"required": ["path"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "edit_file",
				"description": "Edit an existing file by replacing specific text. Use this for making targeted changes to existing files.",
				"parameters": {
					"type": "object",
					"properties": {
						"path": {
							"type": "string",
							"description": "The file path relative to res://"
						},
						"old_text": {
							"type": "string",
							"description": "The exact text to find and replace"
						},
						"new_text": {
							"type": "string",
							"description": "The new text to replace it with"
						}
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
						"path": {
							"type": "string",
							"description": "The file path relative to res://"
						}
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
						"extension": {
							"type": "string",
							"description": "Optional file extension filter (e.g., '.gd', '.tscn')"
						}
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
						"query": {
							"type": "string",
							"description": "The text to search for"
						}
					},
					"required": ["query"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "run_command",
				"description": "Run a shell command (limited to safe operations)",
				"parameters": {
					"type": "object",
					"properties": {
						"command": {
							"type": "string",
							"description": "The command to run"
						}
					},
					"required": ["command"]
				}
			}
		}
	]

static func execute_tool(tool_name: String, arguments: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"data": null
	}
	
	match tool_name:
		"create_file":
			result = _tool_create_file(arguments)
		"read_file":
			result = _tool_read_file(arguments)
		"edit_file":
			result = _tool_edit_file(arguments)
		"delete_file":
			result = _tool_delete_file(arguments)
		"list_files":
			result = _tool_list_files(arguments)
		"search_in_files":
			result = _tool_search_in_files(arguments)
		"run_command":
			result = _tool_run_command(arguments)
		_:
			result.message = "Unknown tool: " + tool_name
	
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
	var content = args.content
	
	var dir_path = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		var err = DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			result.message = "Failed to create directory: " + dir_path
			return result
	
	var file_result = ProjectOpsScript.write_file(path, content)
	if file_result.success:
		EditorInterface.get_resource_filesystem().scan()
		result.success = true
		result.message = "File created successfully: " + path
		result.data = {"path": path}
	else:
		result.message = "Failed to create file: " + file_result.error
	
	return result

static func _tool_read_file(args: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "", "data": null}
	
	if not args.has("path"):
		result.message = "Missing required parameter: path"
		return result
	
	var path = _normalize_path(args.path)
	var file_result = ProjectOpsScript.read_file(path)
	
	if file_result.success:
		result.success = true
		result.message = "File read successfully"
		result.data = {"path": path, "content": file_result.content}
	else:
		result.message = "Failed to read file: " + file_result.error
	
	return result

static func _tool_edit_file(args: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "", "data": null}
	
	if not args.has("path") or not args.has("old_text") or not args.has("new_text"):
		result.message = "Missing required parameters: path, old_text, and new_text"
		return result
	
	var path = _normalize_path(args.path)
	var old_text = args.old_text
	var new_text = args.new_text
	
	var file_result = ProjectOpsScript.read_file(path)
	if not file_result.success:
		result.message = "Failed to read file: " + file_result.error
		return result
	
	var content = file_result.content
	if not old_text in content:
		result.message = "Text not found in file: " + old_text.substr(0, 50) + "..."
		return result
	
	var new_content = content.replace(old_text, new_text)
	var write_result = ProjectOpsScript.write_file(path, new_content)
	
	if write_result.success:
		EditorInterface.get_resource_filesystem().scan()
		result.success = true
		result.message = "File edited successfully: " + path
		result.data = {"path": path}
	else:
		result.message = "Failed to write file: " + write_result.error
	
	return result

static func _tool_delete_file(args: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "", "data": null}
	
	if not args.has("path"):
		result.message = "Missing required parameter: path"
		return result
	
	var path = _normalize_path(args.path)
	
	if not FileAccess.file_exists(path):
		result.message = "File does not exist: " + path
		return result
	
	var err = DirAccess.remove_absolute(path)
	if err == OK:
		EditorInterface.get_resource_filesystem().scan()
		result.success = true
		result.message = "File deleted successfully: " + path
	else:
		result.message = "Failed to delete file: " + str(err)
	
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
		result.message = "Missing required parameter: query"
		return result
	
	var search_results = ProjectOpsScript.find_in_files(args.query)
	result.success = true
	result.message = "Found " + str(search_results.size()) + " matches"
	result.data = {"results": search_results}
	
	return result

static func _tool_run_command(args: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "", "data": null}
	
	if not args.has("command"):
		result.message = "Missing required parameter: command"
		return result
	
	result.message = "Command execution is disabled for safety"
	return result
