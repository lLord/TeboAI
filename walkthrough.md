# TeboAI - Project Walkthrough

## Overview

TeboAI is an AI-powered assistant plugin for the Godot game engine. It provides a chat interface integrated directly into the Godot editor, allowing developers to interact with various AI models for code assistance, debugging, and project management.

## Architecture

### Directory Structure

```
TeboAI/
├── project.godot              # Godot project configuration
├── walkthrough.md             # This file
└── addons/
    └── tebo_ai/
        ├── plugin.cfg         # Plugin metadata
        ├── plugin.gd          # Plugin entry point (EditorPlugin)
        ├── models.json        # AI providers and models configuration
        ├── readme.md          # Installation and usage guide
        ├── scenes/
        │   └── chat_panel.tscn    # UI scene (TabContainer with Chat & Console)
        └── scripts/
            ├── api_client.gd      # HTTP client for AI APIs
            ├── chat_panel.gd      # Main UI logic
            ├── project_ops.gd     # File system operations
            ├── settings.gd        # Configuration management
            └── tools.gd           # Built-in commands (/read, /write, etc.)
```

### Core Components

#### 1. Plugin System (`plugin.gd`)

The main plugin file extends `EditorPlugin` and handles:
- Panel creation and docking to the bottom panel area
- Plugin lifecycle (initialization and cleanup)
- Settings loading on startup

```gdscript
func _enter_tree():
    panel = preload("res://addons/tebo_ai/scenes/chat_panel.tscn").instantiate()
    panel_button = add_control_to_bottom_panel(panel, "TeboAI")
    TeboAISettings.load_settings()
```

#### 2. Settings System (`settings.gd`)

Manages persistent configuration:
- API provider and model selection
- API keys and URLs
- Temperature and system prompts
- Model configuration loaded from `models.json`

Key features:
- Singleton pattern via `get_instance()`
- Automatic loading from `user://tebo_ai_settings.cfg`
- Provider/model lookup functions

#### 3. API Client (`api_client.gd`)

Handles all HTTP communication with AI providers:
- OpenAI-compatible API format
- Anthropic API format support
- Request building with proper headers
- Response parsing for multiple formats
- Debug logging to console

Key methods:
- `send_message()` - Sends chat message to API
- `handle_response()` - Parses and emits response
- `_log_request()` / `_log_response()` - Debug output

#### 4. Chat Panel (`chat_panel.gd`)

Main UI controller with:
- Two tabs: Chat and Console
- Settings popup for configuration
- Message display with BBCode formatting
- Command processing integration

UI Components:
- `messages_container` - Chat history display
- `console_output` - Debug console (RichTextLabel)
- `input_field` - User input (TextEdit)
- Settings controls (OptionButtons, LineEdits, etc.)

#### 5. Project Operations (`project_ops.gd`)

File system utilities:
- `get_project_files()` - Scan project for files
- `read_file()` / `write_file()` - File I/O
- `find_in_files()` - Text search across project
- `get_current_script()` - Get editor's open script
- `get_scene_structure()` - Parse scene files

#### 6. Tools (`tools.gd`)

Built-in command system:
- Command registration with descriptions
- Input parsing and routing
- Output formatting with BBCode

Commands implemented:
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
         │ to AI API  │
         └─────┬──────┘
               │
               ▼
         ┌────────────┐
         │  Response  │
         │   parsed   │
         └─────┬──────┘
               │
               ▼
         ┌────────────┐
         │ Display in │
         │ Chat/Console│
         └────────────┘
```

## Configuration System

### models.json Structure

```json
{
  "providers": [
    {
      "id": "provider_id",
      "name": "Display Name",
      "url": "https://api.endpoint.com/v1/chat/completions",
      "models": [
        {"id": "model-id", "name": "Model Name"}
      ],
      "requires_key": true,
      "headers": {
        "Authorization": "Bearer {api_key}"
      },
      "api_format": "openai"
    }
  ],
  "settings": {
    "max_tokens_default": 4096,
    "temperature_default": 0.7,
    "timeout_seconds": 120
  }
}
```

### Settings Persistence

Settings are saved to `user://tebo_ai_settings.cfg`:
```ini
[api]
provider="openai"
api_key="sk-..."
api_url="https://api.openai.com/v1/chat/completions"
model="gpt-4o"
max_tokens=4096
temperature=0.7
system_prompt="You are TeboAI..."
```

## Supported Providers

### Cloud Providers

| Provider | API Format | Key Required | Notes |
|----------|------------|--------------|-------|
| OpenAI | openai | Yes | GPT-4o, GPT-3.5 |
| OpenRouter | openai | Yes | Free models available |
| Groq | openai | Yes | Fast inference |
| Together AI | openai | Yes | Good free tier |
| DeepSeek | openai | Yes | Coding focused |
| Anthropic | anthropic | Yes | Claude models |

### Local Providers

| Provider | Default URL | Key Required | Notes |
|----------|-------------|--------------|-------|
| Ollama | localhost:11434 | No | Requires ollama serve |
| LM Studio | localhost:1234 | No | Requires server started |

## UI Design

### Tab Structure

1. **Chat Tab**
   - Scrollable message history
   - Color-coded messages (user/assistant/system)
   - Code block formatting
   - Input area with send button

2. **Console Tab**
   - Real-time HTTP communication log
   - Timestamped entries
   - Color-coded by type
   - Clear and Copy buttons

### Settings Popup

- Provider dropdown (from models.json)
- API Key input (hidden)
- URL input (auto-filled, editable)
- Model dropdown (provider-dependent)
- Temperature slider
- System prompt text area
- Save/Cancel buttons

## Extending TeboAI

### Adding a New Provider

1. Edit `models.json`:
```json
{
  "id": "new_provider",
  "name": "New Provider",
  "url": "https://api.newprovider.com/v1/chat/completions",
  "models": [...],
  "requires_key": true,
  "headers": {
    "Authorization": "Bearer {api_key}"
  }
}
```

2. If special API format needed, update `api_client.gd`

### Adding a New Command

1. Add to `tools.gd` `commands` dictionary:
```gdscript
"my_command": {
    "description": "Does something",
    "parameters": ["arg1"],
    "example": "/my_command value"
}
```

2. Add handler in `process_command()`:
```gdscript
"my_command":
    result.output = _cmd_my_command(args)
```

3. Implement the function:
```gdscript
static func _cmd_my_command(args: String) -> String:
    return "Result"
```

## Error Handling

- HTTP errors logged to console with full response
- Missing API key shows user-friendly message
- File operations return success/error dictionaries
- Invalid JSON responses handled gracefully

## Future Improvements

- [ ] Streaming responses
- [ ] Chat history persistence
- [ ] Multi-file context
- [ ] Code diff visualization
- [ ] Custom tool calling
- [ ] Voice input/output

---

*This walkthrough documents TeboAI version 1.0.0*
