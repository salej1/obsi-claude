# Obsidian-Claude Integration Templates

A collection of Obsidian Templater templates that integrate Claude AI directly into your note-taking workflow. Query Claude about your notes, generate summaries, create timelines, and analyze your content seamlessly within Obsidian.

## Features

- **Current Note Analysis** - Ask Claude questions about your currently open note
- **Task Summaries** - Generate summaries of tasks and responsibilities for specific people
- **Timeline Generation** - Create chronological timelines from your notes on any subject
- **Connection Testing** - Verify your Claude API integration is working
- **Debugging Tools** - Troubleshoot configuration and connection issues

## Prerequisites

1. **Obsidian** with the **Templater** plugin installed and enabled
2. **Claude API key** from Anthropic
3. Basic knowledge of Obsidian templates

## Installation

### 1. Copy Templates to Templater Folder

Copy all the template files (`.md` files) to your Templater templates folder:

1. Open Obsidian Settings → Community Plugins → Templater → Settings
2. Note your "Template folder location" (default is `Templates/`)
3. Copy these files to that folder:
   - `aitest.md` - API connection test
   - `debugger.md` - Debugging tool
   - `currentprompt.md` - Current note analysis
   - `summary.md` - Task summaries
   - `timeline.md` - Timeline generation

### 2. Create Configuration File

Create a configuration file in your vault's **root folder** (not in the Templates folder):

**File: `config/claude-config.md`**

```json
# Claude API Configuration

{
  "apiKey": "sk-ant-api03-YOUR-ACTUAL-API-KEY-HERE",
  "model": "claude-3-5-sonnet-20241022",
  "apiUrl": "https://api.anthropic.com/v1/messages",
  "maxTokens": 2000,
  "maxRetries": 3
}
```

⚠️ **Important**: Replace `YOUR-ACTUAL-API-KEY-HERE` with your real Claude API key from [Anthropic Console](https://console.anthropic.com/).

## Usage

### Testing Your Setup

Before using the main templates, test your configuration:

1. **Insert Template**: Use Templater to insert the `aitest` template
2. **Check Results**: The template will test your API connection and display success/error messages
3. **Fix Issues**: If errors occur, verify your API key and configuration

### Debugging Issues

If something isn't working:

1. **Insert Template**: Use the `debugger` template
2. **Review Report**: It will show detailed information about:
   - Configuration file status
   - JSON parsing results
   - API connectivity
   - Current note status
3. **Follow Suggestions**: The debug report will guide you to fix any issues

### Analyzing Current Note

To ask Claude questions about your currently open note:

1. **Open a Note**: Make sure you have a note with content open
2. **Insert Template**: Use the `currentprompt` template
3. **Enter Question**: When prompted, type your question about the note
4. **Get Response**: Claude will analyze your note content and provide an answer

**Example questions:**
- "Summarize the main points"
- "What action items are mentioned?"
- "Extract all dates and deadlines"
- "What are the key insights?"

### Generating Task Summaries

To summarize all tasks/activities for a specific person:

1. **Insert Template**: Use the `summary` template
2. **Enter Name**: When prompted, type the person's name
3. **Get Summary**: Claude will search all your notes and create a comprehensive task summary

**Use cases:**
- Team member responsibility tracking
- Client activity summaries
- Project participant overviews

### Creating Timelines

To generate a chronological timeline for any subject:

1. **Insert Template**: Use the `timeline` template
2. **Enter Subject**: When prompted, type the subject/topic
3. **Get Timeline**: Claude will search your notes and create a chronological timeline

**Example subjects:**
- Project names
- Client names
- Product launches
- Personal goals

## Template Details

| Template | Purpose | Input Required |
|----------|---------|----------------|
| `aitest` | Test API connection | None - automatic |
| `debugger` | Troubleshoot setup | None - automatic |
| `currentprompt` | Analyze current note | Your question |
| `summary` | Task summaries | Person's name |
| `timeline` | Create timelines | Subject/topic |

## Configuration Options

Your `claude-config.md` file supports these options:

```json
{
  "apiKey": "sk-ant-api03-...",           // Required: Your Claude API key
  "model": "claude-3-5-sonnet-20241022",  // Required: Claude model to use
  "apiUrl": "https://api.anthropic.com/v1/messages", // Required: API endpoint
  "maxTokens": 2000,                      // Optional: Max response length (default: 2000)
  "maxRetries": 3                         // Optional: Retry attempts (default: 3)
}
```

## Troubleshooting

### Common Issues

1. **"Configuration file not found"**
   - Ensure `claude-config.md` is in your vault root folder
   - Check that the filename is exactly `claude-config.md`

2. **"No JSON configuration found"**
   - Make sure your JSON is wrapped in markdown code blocks with ```
   - Verify JSON syntax is valid

3. **"API Test Failed"**
   - Check your API key is correct and has credits
   - Verify you have internet connection
   - Ensure API key has proper permissions

4. **"No valid JSON found"**
   - Use the debugger template to see what content was read
   - Check for invisible characters or formatting issues

### Getting Help

1. **Run the debugger template first** - it provides detailed diagnostic information
2. **Check your API key** - ensure it's valid and has available credits
3. **Verify JSON format** - use a JSON validator if needed
4. **Test with aitest template** - confirm basic connectivity works

## Security Notes

- **Never commit your API key** to version control
- **Keep your config file private** - don't share it
- **Regularly rotate API keys** for security
- **Monitor API usage** in the Anthropic Console

## License

These templates are provided as-is for personal and educational use. Please review Anthropic's API terms of service for commercial usage guidelines.