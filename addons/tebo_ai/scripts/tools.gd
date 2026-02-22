extends RefCounted
class_name TeboAITools

const ProjectOpsScript = preload("res://addons/tebo_ai/scripts/project_ops.gd")

static var commands: Dictionary = {
	"read_file": {
		"description": "Read content of a file in the project",
		"parameters": ["path"],
		"example": "/read_file res://scripts/player.gd"
	},
	"write_file": {
		"description": "Write content to a file (creates if not exists)",
		"parameters": ["path", "content"],
		"example": "/write_file res://scripts/test.gd\nextends Node\n\nfunc _ready():\n    print('Hello')"
	},
	"list_files": {
		"description": "List all project files",
		"parameters": [],
		"example": "/list_files"
	},
	"get_current": {
		"description": "Get the currently open script in editor",
		"parameters": [],
		"example": "/get_current"
	},
	"find": {
		"description": "Search for text in project files",
		"parameters": ["search_text"],
		"example": "/find func _ready"
	},
	"project_info": {
		"description": "Get information about the project",
		"parameters": [],
		"example": "/project_info"
	},
	"help": {
		"description": "Show available commands",
		"parameters": [],
		"example": "/help"
	}
}

static func process_command(text: String) -> Dictionary:
	var result = {
		"is_command": false,
		"output": "",
		"success": true
	}
	
	text = text.strip_edges()
	
	if not text.begins_with("/"):
		return result
	
	result.is_command = true
	
	var parts = text.split(" ", false, 1)
	var command = parts[0].substr(1)
	var args = ""
	if parts.size() > 1:
		args = parts[1]
	
	match command:
		"help":
			result.output = _cmd_help()
		"read_file", "read":
			result.output = _cmd_read_file(args)
		"write_file", "write":
			result.output = _cmd_write_file(args)
		"list_files", "ls":
			result.output = _cmd_list_files()
		"get_current", "current":
			result.output = _cmd_get_current()
		"find", "search":
			result.output = _cmd_find(args)
		"project_info", "info":
			result.output = _cmd_project_info()
		_:
			result.output = "Unknown command: " + command + "\nUse /help to see available commands."
			result.success = false
	
	return result

static func _cmd_help() -> String:
	var output = "[b]Available Commands:[/b]\n\n"
	for cmd in commands:
		var info = commands[cmd]
		output += "[color=yellow]/" + cmd + "[/color]\n"
		output += "  " + info.description + "\n"
		output += "  Example: " + info.example + "\n\n"
	return output

static func _cmd_read_file(args: String) -> String:
	if args.is_empty():
		return "[color=red]Error: Missing file path[/color]\nUsage: /read_file <path>"
	
	var path = args.strip_edges()
	if not path.begins_with("res://"):
		path = "res://" + path
	
	var result = ProjectOpsScript.read_file(path)
	if result.success:
		return "[color=green]File: " + path + "[/color]\n\n[code]" + result.content + "[/code]"
	else:
		return "[color=red]Error: " + result.error + "[/color]"

static func _cmd_write_file(args: String) -> String:
	if args.is_empty():
		return "[color=red]Error: Missing arguments[/color]\nUsage: /write_file <path>\\n<content>"
	
	var first_newline = args.find("\n")
	if first_newline == -1:
		return "[color=red]Error: Missing content[/color]\nUsage: /write_file <path>\\n<content>"
	
	var path = args.substr(0, first_newline).strip_edges()
	var content = args.substr(first_newline + 1)
	
	if not path.begins_with("res://"):
		path = "res://" + path
	
	var result = ProjectOpsScript.write_file(path, content)
	if result.success:
		EditorInterface.get_resource_filesystem().scan()
		return "[color=green]File written successfully: " + path + "[/color]"
	else:
		return "[color=red]Error: " + result.error + "[/color]"

static func _cmd_list_files() -> String:
	var files = ProjectOpsScript.get_project_files()
	var output = "[b]Project Files (" + str(files.size()) + "):[/b]\n\n"
	
	var gd_files = []
	var scene_files = []
	var other_files = []
	
	for f in files:
		if f.ends_with(".gd"):
			gd_files.append(f)
		elif f.ends_with(".tscn"):
			scene_files.append(f)
		else:
			other_files.append(f)
	
	if gd_files.size() > 0:
		output += "[color=cyan]GDScript (" + str(gd_files.size()) + "):[/color]\n"
		for f in gd_files:
			output += "  " + f + "\n"
		output += "\n"
	
	if scene_files.size() > 0:
		output += "[color=yellow]Scenes (" + str(scene_files.size()) + "):[/color]\n"
		for f in scene_files:
			output += "  " + f + "\n"
		output += "\n"
	
	if other_files.size() > 0:
		output += "[color=white]Other (" + str(other_files.size()) + "):[/color]\n"
		for f in other_files:
			output += "  " + f + "\n"
	
	return output

static func _cmd_get_current() -> String:
	var result = ProjectOpsScript.get_current_script()
	if result.success:
		return "[color=green]Current Script: " + result.path + "[/color]\n\n[code]" + result.content + "[/code]"
	else:
		return "[color=red]Error: " + result.error + "[/color]"

static func _cmd_find(args: String) -> String:
	if args.is_empty():
		return "[color=red]Error: Missing search text[/color]\nUsage: /find <text>"
	
	var results = ProjectOpsScript.find_in_files(args)
	if results.is_empty():
		return "No results found for: " + args
	
	var output = "[b]Results for '" + args + "' (" + str(results.size()) + " matches):[/b]\n\n"
	for r in results:
		output += "[color=cyan]" + r.file + ":" + str(r.line) + "[/color]\n"
		output += "  " + r.content + "\n"
	
	return output

static func _cmd_project_info() -> String:
	var info = ProjectOpsScript.get_project_info()
	var output = "[b]Project Information:[/b]\n\n"
	output += "GDScript files: " + str(info.gdscript_files) + "\n"
	output += "Scene files: " + str(info.scene_files) + "\n"
	output += "Resource files: " + str(info.resource_files) + "\n"
	output += "Total files: " + str(info.total_files) + "\n"
	return output
