# TeboAI - AI Assistant for Godot

TeboAI is an AI-powered assistant integrated into the Godot editor, designed to help with game development, code generation, debugging, and project management.

## Features

- **Chat Interface**: Interactive chat panel integrated in the Godot editor
- **Multiple AI Providers**: Support for OpenAI, OpenRouter, Groq, Together AI, DeepSeek, Anthropic, and local models
- **Local Models**: Full support for Ollama and LM Studio for offline usage
- **Project Integration**: Read and write project files directly from chat
- **Console Output**: Debug console showing all API communication
- **Customizable**: Configure models, endpoints, and system prompts via `models.json`

## Installation

### Method 1: Manual Installation

1. Download or clone this repository
2. Copy the `addons/tebo_ai` folder to your Godot project's `addons` directory:
   ```
   your_project/
   └── addons/
       └── tebo_ai/
           ├── plugin.cfg
           ├── plugin.gd
           ├── models.json
           ├── scenes/
           └── scripts/
   ```
3. Open your project in Godot
4. Go to **Project → Project Settings → Plugins**
5. Find "TeboAI" in the list and enable it by checking the checkbox
6. The TeboAI panel will appear in the bottom panel area

### Method 2: Asset Library (Coming Soon)

1. Open Godot Editor
2. Go to **Asset Library → Plugins**
3. Search for "TeboAI"
4. Click Install

## Configuration

### Initial Setup

1. Click the **Settings** button in the TeboAI panel
2. Select your preferred **Provider** from the dropdown
3. Enter your **API Key** (if required by the provider)
4. Select a **Model** from the available options
5. Optionally adjust **Temperature** and **System Prompt**
6. Click **Save**

### API Keys

Different providers require API keys. Here's how to obtain them:

| Provider | Get API Key From |
|----------|------------------|
| OpenAI | https://platform.openai.com/api-keys |
| OpenRouter | https://openrouter.ai/keys |
| Groq | https://console.groq.com/keys |
| Together AI | https://api.together.xyz/settings/api-keys |
| DeepSeek | https://platform.deepseek.com/api_keys |
| Anthropic | https://console.anthropic.com/settings/keys |
| Ollama | No key required (local) |
| LM Studio | No key required (local) |

### Local Models (Ollama)

1. Install Ollama from https://ollama.ai
2. Run the Ollama server:
   ```bash
   ollama serve
   ```
3. Download a model:
   ```bash
   ollama pull llama3.2
   ```
4. In TeboAI Settings, select **Ollama (Local)**
5. Choose your downloaded model

### Local Models (LM Studio)

1. Download LM Studio from https://lmstudio.ai
2. Open LM Studio and download a model
3. Go to the **Local Server** tab
4. Click **Start Server** (default port: 1234)
5. In TeboAI Settings, select **LM Studio (Local)**

## Available Commands

TeboAI includes built-in commands for project management:

| Command | Description | Example |
|---------|-------------|---------|
| `/help` | Show all available commands | `/help` |
| `/read_file <path>` | Read a file from the project | `/read_file res://scripts/player.gd` |
| `/write_file <path>` | Write content to a file | `/write_file res://scripts/test.gd` |
| `/list_files` | List all project files | `/list_files` |
| `/get_current` | Get the currently open script | `/get_current` |
| `/find <text>` | Search for text in project files | `/find func _ready` |
| `/project_info` | Get project statistics | `/project_info` |

### Writing Files

To write a file, use the `/write_file` command followed by the path, then a newline, then the content:

```
/write_file res://scripts/hello.gd
extends Node

func _ready():
    print("Hello, TeboAI!")
```

## Customizing Models

Edit `addons/tebo_ai/models.json` to add or modify providers and models:

```json
{
  "id": "my_provider",
  "name": "My Custom Provider",
  "url": "https://api.myprovider.com/v1/chat/completions",
  "models": [
    {"id": "model-1", "name": "Model 1"},
    {"id": "model-2", "name": "Model 2"}
  ],
  "requires_key": true,
  "headers": {
    "Authorization": "Bearer {api_key}"
  }
}
```

### Header Variables

- `{api_key}` - Automatically replaced with your configured API key

### API Formats

- `openai` (default) - OpenAI-compatible API format
- `anthropic` - Anthropic/Claude API format

## Console Tab

The Console tab shows all HTTP communication between TeboAI and the API:

- Request URLs, headers, and bodies
- Response status codes and data
- Error messages and debugging info
- Timestamps for all events

Use the **Copy** button to copy console output for bug reports.

## Troubleshooting

### "API key not configured"
- Open Settings and enter your API key
- Make sure you saved the settings

### "Connection refused" (Local models)
- Ensure Ollama or LM Studio is running
- Check the URL in settings matches the server port

### "Model not found"
- For Ollama: Run `ollama list` to see installed models
- For LM Studio: Make sure a model is loaded
- Edit `models.json` to add your model

### Response is empty or malformed
- Check the Console tab for the full API response
- Verify the model ID matches the provider's requirements
- Some models may have different response formats

## Privacy & Data

- API keys are stored locally in `user://tebo_ai_settings.cfg`
- Chat messages are sent to the configured API provider
- Local models (Ollama/LM Studio) keep all data on your machine

## Support

- Report issues at: https://github.com/your-repo/tebo-ai/issues
- Godot Version: 4.x
- License: MIT

## Credits

TeboAI is inspired by opencode and other AI-assisted development tools.

---

Made with love for the Godot community.
