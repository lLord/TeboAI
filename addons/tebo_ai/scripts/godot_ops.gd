extends RefCounted
class_name TeboAIGodotOps

static var godot_path: String = ""

static func find_godot_path() -> String:
	if not godot_path.is_empty():
		return godot_path
	
	var possible_paths = []
	
	if OS.get_name() == "Windows":
		possible_paths = [
			"C:\\Program Files\\Godot\\Godot_v4.exe",
			"C:\\Program Files\\Godot4\\Godot_v4.exe",
			"C:\\Godot\\Godot_v4.exe",
			OS.get_environment("LOCALAPPDATA") + "\\Godot\\Godot_v4.exe",
			OS.get_environment("PROGRAMFILES") + "\\Godot\\Godot_v4.exe",
		]
	elif OS.get_name() == "macOS":
		possible_paths = [
			"/Applications/Godot.app/Contents/MacOS/Godot",
			"/usr/local/bin/godot4",
			"/opt/homebrew/bin/godot4",
		]
	else:
		possible_paths = [
			"/usr/bin/godot4",
			"/usr/local/bin/godot4",
			"/snap/bin/godot4",
			"/opt/godot/godot4",
		]
	
	for path in possible_paths:
		if FileAccess.file_exists(path):
			godot_path = path
			return godot_path
	
	if godot_path.is_empty():
		for path in possible_paths:
			var test_path = path.get_base_dir()
			if DirAccess.dir_exists_absolute(test_path):
				var files = DirAccess.open(test_path)
				if files:
					files.list_dir_begin()
					var file = files.get_next()
					while file != "":
						if file.to_lower().contains("godot") and file.ends_with(".exe"):
							godot_path = test_path.path_join(file)
							return godot_path
						file = files.get_next()
	
	return godot_path

static func get_godot_version() -> Dictionary:
	var result = {"success": false, "version": "", "full_output": ""}
	
	var path = find_godot_path()
	if path.is_empty():
		result["error"] = "Godot executable not found"
		return result
	
	var output = []
	var exit_code = OS.execute(path, ["--version"], output, true)
	
	if exit_code == 0 and output.size() > 0:
		result["success"] = true
		result["version"] = output[0].strip_edges()
		result["full_output"] = output[0]
	else:
		result["error"] = "Failed to get Godot version"
	
	return result

static func launch_editor(project_path: String = "") -> Dictionary:
	var result = {"success": false, "message": ""}
	
	var path = find_godot_path()
	if path.is_empty():
		result["error"] = "Godot executable not found"
		result["message"] = "Could not find Godot installation. Please set GODOT_PATH."
		return result
	
	var args = []
	if not project_path.is_empty():
		if not project_path.ends_with("project.godot"):
			project_path = project_path.path_join("project.godot")
		args.append(project_path)
	
	var pid = OS.create_process(path, args, false)
	
	if pid > 0:
		result["success"] = true
		result["message"] = "Godot editor launched (PID: " + str(pid) + ")"
		result["pid"] = pid
	else:
		result["message"] = "Failed to launch Godot editor"
	
	return result

static func get_project_info_detailed() -> Dictionary:
	var result = {
		"success": true,
		"project_name": "",
		"godot_version": "",
		"features": [],
		"gdscript_files": 0,
		"scene_files": 0,
		"resource_files": 0,
		"texture_files": 0,
		"audio_files": 0,
		"total_files": 0,
		"project_size_mb": 0.0,
		"autoloads": [],
		"settings": {}
	}
	
	var project_file = "res://project.godot"
	if not FileAccess.file_exists(project_file):
		result["success"] = false
		result["error"] = "project.godot not found"
		return result
	
	var config = ConfigFile.new()
	if config.load(project_file) != OK:
		result["success"] = false
		result["error"] = "Failed to load project.godot"
		return result
	
	result["project_name"] = config.get_value("application", "config/name", "Unnamed Project")
	result["godot_version"] = config.get_value("application", "config/features", ["Unknown"])
	
	var autoload_section = config.get_section_keys("autoload")
	for key in autoload_section:
		result["autoloads"].append({
			"name": key,
			"path": config.get_value("autoload", key)
		})
	
	var settings_keys = config.get_section_keys("application")
	for key in settings_keys:
		result["settings"][key] = config.get_value("application", key)
	
	var files = _get_all_files("res://")
	result["total_files"] = files.size()
	
	var total_size = 0
	for file in files:
		var ext = file.get_extension().to_lower()
		match ext:
			"gd":
				result["gdscript_files"] += 1
			"tscn":
				result["scene_files"] += 1
			"tres":
				result["resource_files"] += 1
			"png", "jpg", "jpeg", "webp", "svg", "bmp":
				result["texture_files"] += 1
			"wav", "ogg", "mp3":
				result["audio_files"] += 1
		
		var f = FileAccess.open(file, FileAccess.READ)
		if f:
			total_size += f.get_length()
	
	result["project_size_mb"] = snapped(float(total_size) / 1024.0 / 1024.0, 0.01)
	
	return result

static func _get_all_files(path: String, files: Array = []) -> Array:
	var dir = DirAccess.open(path)
	if not dir:
		return files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not file_name.begins_with(".") and file_name != "project.godot":
			var full_path = path.path_join(file_name)
			if dir.current_is_dir():
				if file_name not in [".godot", "addons", ".import"]:
					_get_all_files(full_path, files)
			else:
				files.append(full_path)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return files

static func parse_scene_file(path: String) -> Dictionary:
	var result = {
		"success": false,
		"root_node": "",
		"nodes": [],
		"connections": [],
		"resources": []
	}
	
	if not FileAccess.file_exists(path):
		result["error"] = "Scene file not found"
		return result
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		result["error"] = "Could not open scene file"
		return result
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	var current_node = {}
	var in_node = false
	
	for line in lines:
		line = line.strip_edges()
		
		if line.begins_with("[node name=\""):
			if in_node and current_node.has("name"):
				result["nodes"].append(current_node)
			current_node = {}
			in_node = true
			
			var name_match = _extract_quoted_value(line, "name")
			var type_match = _extract_quoted_value(line, "type")
			var parent_match = _extract_quoted_value(line, "parent")
			
			current_node["name"] = name_match
			if not type_match.is_empty():
				current_node["type"] = type_match
			if not parent_match.is_empty():
				current_node["parent"] = parent_match
		
		elif line.begins_with("[ext_resource"):
			var res_type = _extract_quoted_value(line, "type")
			var res_path = _extract_quoted_value(line, "path")
			var res_id = _extract_quoted_value(line, "id")
			result["resources"].append({
				"type": res_type,
				"path": res_path,
				"id": res_id
			})
		
		elif line.begins_with("[connection"):
			var signal_name = _extract_quoted_value(line, "signal")
			var from_node = _extract_quoted_value(line, "from")
			var to_node = _extract_quoted_value(line, "to")
			var method_name = _extract_quoted_value(line, "method")
			result["connections"].append({
				"signal": signal_name,
				"from": from_node,
				"to": to_node,
				"method": method_name
			})
		
		elif in_node:
			if line.begins_with("script"):
				var script_path = _extract_quoted_value(line, "script")
				current_node["script"] = script_path
			elif "position" in line:
				current_node["position"] = line.split("=")[1].strip_edges()
			elif "scale" in line and "scale" not in current_node:
				current_node["scale"] = line.split("=")[1].strip_edges()
	
	if in_node and current_node.has("name"):
		result["nodes"].append(current_node)
	
	if result["nodes"].size() > 0:
		result["root_node"] = result["nodes"][0].get("name", "")
	
	result["success"] = true
	return result

static func _extract_quoted_value(text: String, key: String) -> String:
	var pattern = key + "=\""
	var start = text.find(pattern)
	if start == -1:
		return ""
	start += pattern.length()
	var end = text.find("\"", start)
	if end == -1:
		return ""
	return text.substr(start, end - start)

static func create_scene(root_node_type: String, root_node_name: String, script_path: String = "") -> Dictionary:
	var result = {"success": false, "content": ""}
	
	var uid = "uid://" + _generate_uid()
	var timestamp = Time.get_unix_time_from_system()
	
	var content = "[gd_scene load_steps=2 format=3 uid=\"" + uid + "\"]\n\n"
	
	if not script_path.is_empty():
		if not script_path.begins_with("res://"):
			script_path = "res://" + script_path
		content += "[ext_resource type=\"Script\" path=\"" + script_path + "\" id=\"1_script\"]\n\n"
	
	content += "[node name=\"" + root_node_name + "\" type=\"" + root_node_type + "\"]\n"
	
	if not script_path.is_empty():
		content += "script = ExtResource(\"1_script\")\n"
	
	result["success"] = true
	result["content"] = content
	return result

static func add_node_to_scene(scene_path: String, node_type: String, node_name: String, parent_path: String = ".", properties: Dictionary = {}) -> Dictionary:
	var result = {"success": false, "message": ""}
	
	if not scene_path.begins_with("res://"):
		scene_path = "res://" + scene_path
	
	if not FileAccess.file_exists(scene_path):
		result["error"] = "Scene file not found: " + scene_path
		return result
	
	var file = FileAccess.open(scene_path, FileAccess.READ)
	if not file:
		result["error"] = "Could not open scene file"
		return result
	
	var content = file.get_as_text()
	file.close()
	
	var load_steps = 2
	
	if "[gd_scene load_steps=" in content:
		var steps_start = content.find("load_steps=") + 11
		var steps_end = content.find(" ", steps_start)
		if steps_end == -1:
			steps_end = content.find("]", steps_start)
		var current_steps = content.substr(steps_start, steps_end - steps_start).to_int()
		load_steps = current_steps + 1
		content = content.replace("load_steps=" + str(current_steps), "load_steps=" + str(load_steps))
	
	var node_section = "\n[node name=\"" + node_name + "\" type=\"" + node_type + "\""
	if parent_path != "." and not parent_path.is_empty():
		node_section += " parent=\"" + parent_path + "\""
	node_section += "]\n"
	
	for key in properties:
		var value = properties[key]
		if value is String:
			if value.begins_with("res://") or value.begins_with("ExtResource"):
				node_section += key + " = " + value + "\n"
			else:
				node_section += key + " = \"" + value + "\"\n"
		elif value is Vector2:
			node_section += key + " = Vector2(" + str(value.x) + ", " + str(value.y) + ")\n"
		elif value is Color:
			node_section += key + " = Color(" + str(value.r) + ", " + str(value.g) + ", " + str(value.b) + ", " + str(value.a) + ")\n"
		elif value is bool:
			node_section += key + " = " + str(value).to_lower() + "\n"
		elif value is int or value is float:
			node_section += key + " = " + str(value) + "\n"
		else:
			node_section += key + " = " + str(value) + "\n"
	
	content += node_section
	
	var write_file = FileAccess.open(scene_path, FileAccess.WRITE)
	if not write_file:
		result["error"] = "Could not write to scene file"
		return result
	
	write_file.store_string(content)
	write_file.close()
	
	result["success"] = true
	result["message"] = "Node '" + node_name + "' added to scene"
	return result

static func load_sprite_to_node(scene_path: String, node_name: String, texture_path: String) -> Dictionary:
	var result = {"success": false, "message": ""}
	
	if not scene_path.begins_with("res://"):
		scene_path = "res://" + scene_path
	if not texture_path.begins_with("res://"):
		texture_path = "res://" + texture_path
	
	if not FileAccess.file_exists(scene_path):
		result["error"] = "Scene file not found"
		return result
	
	if not FileAccess.file_exists(texture_path):
		result["error"] = "Texture file not found: " + texture_path
		return result
	
	var file = FileAccess.open(scene_path, FileAccess.READ)
	if not file:
		result["error"] = "Could not open scene file"
		return result
	
	var content = file.get_as_text()
	file.close()
	
	var load_steps = 2
	if "[gd_scene load_steps=" in content:
		var steps_start = content.find("load_steps=") + 11
		var steps_end = content.find(" ", steps_start)
		if steps_end == -1:
			steps_end = content.find("]", steps_start)
		var current_steps = content.substr(steps_start, steps_end - steps_start).to_int()
		load_steps = current_steps + 1
		content = content.replace("load_steps=" + str(current_steps), "load_steps=" + str(load_steps))
	
	var ext_resource_id = "1_texture"
	var counter = 1
	while "ExtResource(\"" + str(counter) in content:
		counter += 1
	ext_resource_id = str(counter)
	
	var ext_resource = "[ext_resource type=\"Texture2D\" path=\"" + texture_path + "\" id=\"" + ext_resource_id + "\"]\n"
	
	var first_node_pos = content.find("[node ")
	if first_node_pos == -1:
		result["error"] = "Invalid scene format"
		return result
	
	content = content.insert(first_node_pos, ext_resource)
	
	var node_pattern = "[node name=\"" + node_name + "\""
	var node_pos = content.find(node_pattern)
	if node_pos == -1:
		result["error"] = "Node '" + node_name + "' not found in scene"
		return result
	
	var node_end = content.find("\n[", node_pos + 1)
	if node_end == -1:
		node_end = content.length()
	
	var node_content = content.substr(node_pos, node_end - node_pos)
	
	if "type=\"Sprite2D\"" not in node_content and "type=\"Sprite3D\"" not in node_content:
		var type_start = node_content.find("type=\"")
		if type_start != -1:
			node_content = node_content.replace(node_content.substr(type_start, node_content.find("\"", type_start + 6) - type_start + 1), "type=\"Sprite2D\"")
	
	if "texture =" in node_content:
		node_content = node_content.replace("texture = ExtResource(\"" + node_content.split("texture = ExtResource(\"")[1].split("\")")[0] + "\")", "texture = ExtResource(\"" + ext_resource_id + "\")")
	else:
		var insert_pos = node_content.find("]")
		if insert_pos != -1:
			node_content = node_content.insert(insert_pos + 1, "\ntexture = ExtResource(\"" + ext_resource_id + "\")")
	
	content = content.substr(0, node_pos) + node_content + content.substr(node_end)
	
	var write_file = FileAccess.open(scene_path, FileAccess.WRITE)
	if not write_file:
		result["error"] = "Could not write to scene file"
		return result
	
	write_file.store_string(content)
	write_file.close()
	
	result["success"] = true
	result["message"] = "Texture loaded to node '" + node_name + "'"
	return result

static func get_file_uid(file_path: String) -> Dictionary:
	var result = {"success": false, "uid": "", "error": ""}
	
	if not file_path.begins_with("res://"):
		file_path = "res://" + file_path
	
	if not FileAccess.file_exists(file_path):
		result["error"] = "File not found: " + file_path
		return result
	
	var ext = file_path.get_extension().to_lower()
	
	if ext in ["gd", "tscn", "tres", "shader"]:
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var first_lines = ""
			for i in range(5):
				var line = file.get_line()
				if line.is_empty():
					continue
				first_lines += line + "\n"
			
			if "uid://" in first_lines:
				var uid_start = first_lines.find("uid://")
				var uid_end = first_lines.find("\"", uid_start)
				if uid_end == -1:
					uid_end = first_lines.find("'", uid_start)
				if uid_end > uid_start:
					result["uid"] = first_lines.substr(uid_start, uid_end - uid_start)
					result["success"] = true
			file.close()
	
	if not result["success"]:
		var meta_path = file_path + ".uid"
		if FileAccess.file_exists(meta_path):
			var meta_file = FileAccess.open(meta_path, FileAccess.READ)
			if meta_file:
				result["uid"] = meta_file.get_as_text().strip_edges()
				result["success"] = true
				meta_file.close()
	
	if not result["success"]:
		result["error"] = "Could not find UID for file"
	
	return result

static func _generate_uid() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	var result = ""
	for i in range(16):
		result += chars[randi() % chars.length()]
	return result

static func get_editor_interface():
	return EditorInterface

static func get_current_scene() -> Dictionary:
	var result = {"success": false, "path": "", "name": "", "nodes": []}
	
	var editor = EditorInterface
	if not editor:
		result["error"] = "Editor interface not available"
		return result
	
	var scene = editor.get_edited_scene_root()
	if not scene:
		result["error"] = "No scene open"
		return result
	
	result["success"] = true
	result["path"] = scene.scene_file_path
	result["name"] = scene.name
	
	var nodes = _get_node_children(scene)
	result["nodes"] = nodes
	
	return result

static func _get_node_children(node: Node, depth: int = 0) -> Array:
	if depth > 10:
		return []
	
	var result = []
	for child in node.get_children():
		var node_info = {
			"name": child.name,
			"type": child.get_class(),
			"children": _get_node_children(child, depth + 1)
		}
		result.append(node_info)
	
	return result

static func get_all_autoloads() -> Array:
	var result = []
	var project_file = "res://project.godot"
	
	if not FileAccess.file_exists(project_file):
		return result
	
	var config = ConfigFile.new()
	if config.load(project_file) != OK:
		return result
	
	var keys = config.get_section_keys("autoload")
	for key in keys:
		result.append({
			"name": key,
			"path": config.get_value("autoload", key)
		})
	
	return result
