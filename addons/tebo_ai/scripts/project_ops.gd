extends RefCounted
class_name TeboAIProjectOps

static func get_project_files(extension_filter: Array = ["*.gd", "*.tscn", "*.tres"]) -> Array:
	var files = []
	_scan_directory("res://", files, extension_filter)
	return files

static func _scan_directory(path: String, files: Array, filters: Array):
	var dir = DirAccess.open(path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not file_name.begins_with("."):
			var full_path = path.path_join(file_name)
			
			if dir.current_is_dir():
				if file_name not in ["addons", ".godot", ".import"]:
					_scan_directory(full_path, files, filters)
			else:
				for filter in filters:
					if file_name.match(filter):
						files.append(full_path)
						break
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

static func read_file(path: String) -> Dictionary:
	var result = {
		"success": false,
		"content": "",
		"error": ""
	}
	
	if not FileAccess.file_exists(path):
		result.error = "File not found: " + path
		return result
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		result.error = "Cannot open file: " + str(FileAccess.get_open_error())
		return result
	
	result.content = file.get_as_text()
	result.success = true
	file.close()
	
	return result

static func write_file(path: String, content: String) -> Dictionary:
	var result = {
		"success": false,
		"error": ""
	}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		result.error = "Cannot write to file: " + str(FileAccess.get_open_error())
		return result
	
	file.store_string(content)
	file.close()
	result.success = true
	
	return result

static func create_file(path: String, content: String = "") -> Dictionary:
	var result = {
		"success": false,
		"error": ""
	}
	
	var dir_path = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		var err = DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			result.error = "Cannot create directory: " + str(err)
			return result
	
	return write_file(path, content)

static func get_current_script() -> Dictionary:
	var result = {
		"success": false,
		"path": "",
		"content": "",
		"error": ""
	}
	
	var script_editor = EditorInterface.get_script_editor()
	if not script_editor:
		result.error = "Script editor not available"
		return result
	
	var current_script = script_editor.get_current_script()
	if not current_script:
		result.error = "No script open"
		return result
	
	result.path = current_script.resource_path
	result.success = true
	
	var file_result = read_file(result.path)
	result.content = file_result.content
	if not file_result.success:
		result.error = file_result.error
		result.success = false
	
	return result

static func get_scene_structure(scene_path: String) -> Dictionary:
	var result = {
		"success": false,
		"nodes": [],
		"error": ""
	}
	
	if not FileAccess.file_exists(scene_path):
		result.error = "Scene not found"
		return result
	
	var file = FileAccess.open(scene_path, FileAccess.READ)
	if not file:
		result.error = "Cannot open scene"
		return result
	
	var content = file.get_as_text()
	file.close()
	
	var regex = RegEx.new()
	regex.compile("\\[node\\s+name=\"([^\"]+)\"[^\\]]*type=\"([^\"]+)\"")
	
	for match in regex.search_all(content):
		result.nodes.append({
			"name": match.get_string(1),
			"type": match.get_string(2)
		})
	
	result.success = true
	return result

static func find_in_files(search_text: String, extensions: Array = ["*.gd"]) -> Array:
	var results = []
	var files = get_project_files(extensions)
	
	for file_path in files:
		var read_result = read_file(file_path)
		if read_result.success:
			var lines = read_result.content.split("\n")
			for i in range(lines.size()):
				if search_text.to_lower() in lines[i].to_lower():
					results.append({
						"file": file_path,
						"line": i + 1,
						"content": lines[i].strip_edges()
					})
	
	return results

static func get_project_info() -> Dictionary:
	var info = {
		"gdscript_files": 0,
		"scene_files": 0,
		"resource_files": 0,
		"total_files": 0
	}
	
	var files = get_project_files(["*.gd", "*.tscn", "*.tres"])
	info.total_files = files.size()
	
	for f in files:
		if f.ends_with(".gd"):
			info.gdscript_files += 1
		elif f.ends_with(".tscn"):
			info.scene_files += 1
		elif f.ends_with(".tres"):
			info.resource_files += 1
	
	return info
