# TeboAI - Project Walkthrough

## Overview

TeboAI is an AI-powered assistant plugin for the Godot 4.x game engine. It provides a chat interface integrated directly into the Godot editor's right dock, allowing developers to interact with various AI models for code assistance, debugging, and project management with automatic tool calling capabilities.

## Architecture

### Directory Structure

```
TeboAI/
├── project.godot              # Godot project configuration
├── README.md                  # Public documentation for GitHub
├── walkthrough.md             # This file - development guide
└── addons/
    └── tebo_ai/
        ├── plugin.cfg         # Plugin metadata
        ├── plugin.gd          # Plugin entry point (EditorPlugin)
        ├── models.json        # AI providers and models configuration
        ├── readme.md          # Installation and usage guide
        ├── scenes/
        │   └── chat_panel.tscn    # UI scene (TabContainer with Chat & Console)
        └── scripts/
            ├── api_client.gd      # HTTP client for AI APIs with tool calling
            ├── chat_panel.gd      # Main UI logic
            ├── godot_ops.gd       # Godot-specific operations (scenes, resources)
            ├── project_ops.gd     # File system operations
            ├── settings.gd        # Configuration management with persistence
            ├── tool_executor.gd   # Tool definitions and execution
            └── tools.gd           # Built-in commands (/read, /write, etc.)
```

### Core Components

#### 1. Plugin System (`plugin.gd`)

The main plugin file extends `EditorPlugin` and handles:
- Panel creation and docking to the right dock area
- Plugin lifecycle (initialization and cleanup)
- Settings loading on startup

```gdscript
func _enter_tree():
    panel = preload("res://addons/tebo_ai/scenes/chat_panel.tscn").instantiate()
    add_control_to_dock(DOCK_SLOT_RIGHT_UR, panel)
    TeboAISettings.load_settings()
```

#### 2. Settings System (`settings.gd`)

Manages persistent configuration:
- API provider and model selection (persisted between sessions)
- API keys and URLs
- Temperature and system prompts
- Model configuration loaded from `models.json`

Key features:
- Singleton pattern via `get_instance()`
- Automatic loading from `user://tebo_ai_settings.cfg`
- Provider/model lookup functions
- Proper initialization order for persistence

```gdscript
static func get_instance() -> TeboAISettings:
    if not instance:
        instance = TeboAISettings.new()
        instance.load_models_config()
        instance._load_from_file()
    return instance
```

#### 3. API Client (`api_client.gd`)

Handles all HTTP communication with AI providers:
- OpenAI-compatible API format with tool calling support
- Anthropic API format support
- Request building with proper headers and tool definitions
- Response parsing for multiple formats
- Automatic tool execution loop
- Debug logging to console

Key methods:
- `send_message()` - Sends chat message with tool definitions
- `_handle_tool_calls()` - Processes and executes tool calls
- `_send_request()` - Recursive request for tool follow-ups
- `_build_openai_body()` - Builds request with tools array

#### 4. Tool Executor (`tool_executor.gd`)

Defines and executes AI tools:

**File Operations:**
| Tool | Description |
|------|-------------|
| `create_file` | Create or overwrite files |
| `read_file` | Read file content |
| `edit_file` | Replace text in files |
| `delete_file` | Remove files |
| `list_files` | List project files |
| `search_in_files` | Search across files |

**Godot Engine:**
| Tool | Description |
|------|-------------|
| `get_godot_version` | Get installed Godot version |
| `get_project_info` | Detailed project analysis |
| `launch_editor` | Open Godot editor |

**Scene Management:**
| Tool | Description |
|------|-------------|
| `create_scene` | Create scenes with root nodes |
| `add_node_to_scene` | Add nodes to existing scenes |
| `parse_scene` | Get scene structure |
| `get_current_scene` | Info about open scene |

**Resources:**
| Tool | Description |
|------|-------------|
| `load_sprite` | Load textures into Sprite2D |
| `list_textures` | Find all image files |
| `list_audio` | Find all audio files |

**Advanced:**
| Tool | Description |
|------|-------------|
| `get_file_uid` | Get file UIDs (Godot 4.4+) |
| `get_autoloads` | List autoload configurations |

#### 5. Godot Operations (`godot_ops.gd`)

Godot-specific operations:
- `find_godot_path()` - Locate Godot executable
- `get_godot_version()` - Get version info
- `launch_editor()` - Start editor process
- `get_project_info_detailed()` - Full project analysis
- `parse_scene_file()` - Parse .tscn files
- `create_scene()` - Generate scene content
- `add_node_to_scene()` - Modify existing scenes
- `load_sprite_to_node()` - Load textures
- `get_file_uid()` - Get resource UIDs
- `get_current_scene()` - Editor scene info

#### 6. Chat Panel (`chat_panel.gd`)

Main UI controller with:
- Two tabs: Chat and Console
- Settings popup for configuration
- Message display with BBCode formatting
- Command processing integration
- Animated status indicator

Status States:
- ○ Gray - Ready
- ● Yellow pulsing - Thinking...
- ✓ Green - Done
- ✗ Red - Error

```gdscript
func _set_status_thinking():
    is_thinking = true
    animation_timer.start()
    status_icon.text = "[color=yellow]●[/color]"
    status_label.text = "Thinking"
```

#### 7. Project Operations (`project_ops.gd`)

File system utilities:
- `get_project_files()` - Scan project for files
- `read_file()` / `write_file()` - File I/O
- `find_in_files()` - Text search across project
- `get_current_script()` - Get editor's open script

#### 8. Tools (`tools.gd`)

Built-in command system for manual use:
- Command registration with descriptions
- Input parsing and routing
- Output formatting with BBCode

Commands:
| Command | Function |
|---------|----------|
| `/help` | Show command list |
| `/read_file` | Read project file |
| `/write_file` | Write/create file |
| `/list_files` | List project files |
| `/get_current` | Get open script |
| `/find` | Search in project |
| `/project_info` | Project statistics |

## Data Flow

```
User Input
    │
    ▼
┌─────────────────┐
│   chat_panel.gd │
└────────┬────────┘
         │
    ┌────▼────┐
    │ Is cmd? │
    └────┬────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌───────┐ ┌───────────┐
│ tools │ │api_client │
└───────┘ └─────┬─────┘
                │
                ▼
         ┌────────────┐
         │ HTTP POST  │
         │ + tools    │
         └─────┬──────┘
               │
               ▼
         ┌────────────┐
         │ AI Response│
         │ tool_calls?│
         └─────┬──────┘
               │
         ┌─────┴─────┐
         │           │
         ▼           ▼
    ┌─────────┐ ┌────────────┐
    │ Content │ │Tool Calls  │
    │Display  │ │→ Execute   │
    └─────────┘ │→ New Req   │
                └────────────┘
```

## Configuration System

### models.json Structure

```json
{
  "providers": [
    {
      "id": "opencode-zen",
      "name": "OpenCode Zen (Free)",
      "url": "https://opencode.ai/zen/v1/chat/completions",
      "models": [
        {"id": "big-pickle", "name": "Big Pickle (Free)"},
        {"id": "glm-4.7-free", "name": "GLM 4.7 Free"},
        {"id": "kimi-k2.5-free", "name": "Kimi K2.5 Free"},
        {"id": "minimax-m2.1-free", "name": "MiniMax M2.1 Free"}
      ],
      "requires_key": true,
      "headers": {
        "Authorization": "Bearer {api_key}"
      }
    }
  ]
}
```

### Settings Persistence

Settings saved to `user://tebo_ai_settings.cfg`:
```ini
[api]
provider="opencode-zen"
api_key="your-key"
api_url="https://opencode.ai/zen/v1/chat/completions"
model="big-pickle"
max_tokens=4096
temperature=0.7
system_prompt="You are TeboAI..."
```

## Supported Providers

### Cloud Providers

| Provider | API Format | Key Required | Notes |
|----------|------------|--------------|-------|
| OpenAI | openai | Yes | GPT-4o, GPT-3.5 |
| OpenCode Zen | openai | Yes | Free models |
| OpenRouter | openai | Yes | Free models available |
| Groq | openai | Yes | Fast inference |
| Together AI | openai | Yes | Good free tier |
| DeepSeek | openai | Yes | Coding focused |
| Anthropic | anthropic | Yes | Claude models |

### Local Providers

| Provider | Default URL | Key Required |
|----------|-------------|--------------|
| Ollama | localhost:11434 | No |
| LM Studio | localhost:1234 | No |

## UI Design

### Panel Location

The plugin docks to the **right dock** (DOCK_SLOT_RIGHT_UR) in vertical format.

### Tab Structure

1. **Chat Tab**
   - Scrollable message history
   - Color-coded messages (user/assistant/system)
   - Code block formatting
   - Input area with send button

2. **Console Tab**
   - Real-time HTTP communication log
   - Timestamped entries
   - Color-coded by type (ERROR, INFO, DEBUG, TOOL)
   - Clear and Copy buttons

### Status Bar

Bottom status bar showing:
- Animated status icon (● yellow pulsing when thinking)
- Status text ("Thinking...", "Done", "Error", "Ready")

### Settings Popup

- Provider dropdown (from models.json)
- API Key input (hidden)
- URL input (auto-filled, editable)
- Model dropdown (provider-dependent)
- Temperature slider
- System prompt text area
- Save/Cancel buttons

## Development History

### Phase 1: Initial Setup
- Created basic plugin structure
- Implemented chat interface in bottom panel
- Added support for multiple AI providers
- Created models.json configuration

### Phase 2: Debug Improvements
- Added console logging for HTTP requests/responses
- Improved error handling and display
- Fixed JSON parsing issues

### Phase 3: OpenCode Zen Integration
- Added OpenCode Zen as free provider option
- Added 4 free models (Big Pickle, GLM 4.7, Kimi K2.5, MiniMax M2.1)

### Phase 4: Tool Calling Implementation
- Implemented automatic tool calling system
- Created tool_executor.gd with tool definitions
- Modified api_client.gd to handle tool_calls
- Added recursive request loop for multi-tool operations
- Updated system prompt with tool instructions

### Phase 5: Advanced Godot Tools
- Created godot_ops.gd for Godot-specific operations
- Added scene management tools (create_scene, add_node_to_scene, parse_scene)
- Added resource tools (load_sprite, list_textures, list_audio)
- Added project analysis tools (get_project_info, get_godot_version)
- Added UID management for Godot 4.4+

### Phase 6: UI Improvements
- Moved plugin from bottom panel to right dock
- Adjusted UI for vertical layout
- Added animated status indicator
- Added status bar with thinking/success/error states

### Phase 7: Settings Persistence Fix
- Fixed provider/model not saving between sessions
- Improved initialization order in settings.gd
- Added debug logging for settings operations

## Extending TeboAI

### Adding a New Provider

1. Edit `models.json`:
```json
{
  "id": "new_provider",
  "name": "New Provider",
  "url": "https://api.newprovider.com/v1/chat/completions",
  "models": [
    {"id": "model-1", "name": "Model One"}
  ],
  "requires_key": true,
  "headers": {
    "Authorization": "Bearer {api_key}"
  }
}
```

2. If special API format needed, update `api_client.gd`

### Adding a New Tool

1. Add definition in `tool_executor.gd` `get_tool_definitions()`:
```gdscript
{
    "type": "function",
    "function": {
        "name": "my_tool",
        "description": "Does something",
        "parameters": {
            "type": "object",
            "properties": {
                "arg1": {"type": "string", "description": "First arg"}
            },
            "required": ["arg1"]
        }
    }
}
```

2. Add execution in `execute_tool()`:
```gdscript
"my_tool": result = _tool_my_tool(arguments)
```

3. Implement the function:
```gdscript
static func _tool_my_tool(args: Dictionary) -> Dictionary:
    return {"success": true, "message": "Done", "data": null}
```

### Adding a New Command

1. Add to `tools.gd` `commands` dictionary
2. Add handler in `process_command()`
3. Implement the function

## Error Handling

- HTTP errors logged to console with full response
- Missing API key shows user-friendly message
- Tool execution errors displayed in chat
- Invalid JSON responses handled gracefully
- Tool call failures don't crash the loop

## Future Improvements

- [ ] Streaming responses
- [ ] Chat history persistence
- [ ] Code diff visualization
- [ ] Run project and capture debug output
- [ ] Export MeshLibrary tool
- [ ] Voice input/output

---

*This walkthrough documents TeboAI - Last updated after settings persistence fix*
