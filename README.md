# TeboAI - AI Assistant Plugin for Godot

An AI-powered assistant plugin for the Godot game engine that provides intelligent code assistance, project management, and automated file operations directly within the editor.

## Features

### AI Chat Integration
- Chat interface integrated directly into Godot's bottom panel
- Support for multiple AI providers:
  - **OpenAI** (GPT-4o, GPT-4 Turbo, GPT-3.5)
  - **OpenCode Zen** (Free models: Big Pickle, GLM 4.7 Free, Kimi K2.5 Free, MiniMax M2.1 Free)
  - **OpenRouter** (Free Llama, Qwen, Gemma models)
  - **Groq** (Fast inference)
  - **Together AI**
  - **DeepSeek**
  - **Anthropic** (Claude 3.5 Sonnet, Haiku, Opus)
  - **Ollama** (Local)
  - **LM Studio** (Local)
- Real-time HTTP request/response logging in Console tab
- Configurable temperature, max tokens, and system prompts

### Automatic Tool Calling
TeboAI can automatically execute operations on your project using these tools:

#### File Operations
| Tool | Description |
|------|-------------|
| `create_file` | Create or overwrite files in the project |
| `read_file` | Read content of any project file |
| `edit_file` | Make targeted edits by replacing specific text |
| `delete_file` | Remove files from the project |
| `list_files` | List all project files with optional extension filter |
| `search_in_files` | Search for text across all project files |

#### Godot Engine
| Tool | Description |
|------|-------------|
| `get_godot_version` | Get the installed Godot version |
| `get_project_info` | Detailed project structure analysis |
| `launch_editor` | Open the Godot editor |

#### Scene Management
| Tool | Description |
|------|-------------|
| `create_scene` | Create new scenes with specified root node types |
| `add_node_to_scene` | Add nodes to existing scenes with properties |
| `parse_scene` | Get complete scene structure (nodes, connections, resources) |
| `get_current_scene` | Information about the currently open scene |

#### Resources
| Tool | Description |
|------|-------------|
| `load_sprite` | Load textures into Sprite2D nodes |
| `list_textures` | Find all image files in the project |
| `list_audio` | Find all audio files in the project |

#### Advanced
| Tool | Description |
|------|-------------|
| `get_file_uid` | Get UID for files (Godot 4.4+) |
| `get_autoloads` | List all autoload/singleton configurations |

## Installation

1. Download or clone this repository into your Godot project's `addons` folder:
   ```
   your_project/
   └── addons/
       └── tebo_ai/
   ```

2. In Godot, go to **Project → Project Settings → Plugins**

3. Find **TeboAI** in the list and enable it

4. The TeboAI panel will appear in the **right dock** area

## Configuration

### Setting Up an AI Provider

1. Click the **Settings** button in the TeboAI panel
2. Select a **Provider** from the dropdown
3. Enter your **API Key** (not required for local providers like Ollama)
4. Select a **Model** from the dropdown
5. Adjust **Temperature** if needed (0.0 - 2.0)
6. Optionally customize the **System Prompt**
7. Click **Save**

### Recommended Free Models

For users without paid API access, these free options are available:

| Provider | Model | Notes |
|----------|-------|-------|
| OpenCode Zen | Big Pickle | Free, no rate limits |
| OpenCode Zen | GLM 4.7 Free | Free, coding focused |
| OpenCode Zen | Kimi K2.5 Free | Free, multilingual |
| OpenCode Zen | MiniMax M2.1 Free | Free, good reasoning |
| OpenRouter | Llama 3.2 3B | Free tier available |
| Ollama | Any model | Requires local installation |

## Usage Examples

### Creating Files
```
Create a player movement script at scripts/player.gd with WASD controls
```

### Creating Scenes
```
Create a scene at scenes/enemy.tscn with a CharacterBody2D root node named "Enemy"
```

### Adding Nodes
```
Add a CollisionShape2D to the Enemy scene with a rectangle shape
```

### Analyzing Projects
```
What's the structure of my project? How many scripts and scenes do I have?
```

### Searching Code
```
Search for all uses of _ready function in my project
```

### Loading Resources
```
Load the sprite assets/characters/player.png into the Player's Sprite2D node
```

## Architecture

```
TeboAI/
├── addons/
│   └── tebo_ai/
│       ├── plugin.cfg           # Plugin metadata
│       ├── plugin.gd            # EditorPlugin entry point
│       ├── models.json          # AI providers configuration
│       ├── readme.md            # Installation guide
│       ├── scenes/
│       │   └── chat_panel.tscn  # UI scene
│       └── scripts/
│           ├── api_client.gd    # HTTP client for AI APIs
│           ├── chat_panel.gd    # Main UI controller
│           ├── godot_ops.gd     # Godot-specific operations
│           ├── project_ops.gd   # File system operations
│           ├── settings.gd      # Configuration management
│           ├── tool_executor.gd # Tool definitions and execution
│           └── tools.gd         # Built-in commands
```

## Requirements

- Godot 4.x
- Internet connection (for cloud AI providers)
- API key for chosen provider (except local providers)

## Troubleshooting

### Plugin not appearing
- Ensure the plugin is enabled in Project Settings → Plugins
- Check the Output console for error messages

### API errors
- Verify your API key is correct
- Check the Console tab for detailed HTTP logs
- Ensure the API URL is correct for your provider

### No response from AI
- Check if you've exceeded API rate limits
- Verify the model ID is correct
- Review the Console tab for error details

## License

MIT License - feel free to use in your projects.

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests

## Acknowledgments

- Inspired by [godot-mcp](https://github.com/Coding-Solo/godot-mcp)
- Built for the Godot community
