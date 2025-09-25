<%*
// Claude Current Note Query Template - Fixed Version

// Function to load configuration with better error handling
async function loadConfig() {
    try {
        // Try multiple possible paths for the config file
        const possiblePaths = [
            "config/claude-config.md",
            "Config/claude-config.md", 
            "claude-config.md"
        ];
        
        let configFile = null;
        let usedPath = null;
        
        for (const path of possiblePaths) {
            configFile = app.vault.getAbstractFileByPath(path);
            if (configFile) {
                usedPath = path;
                break;
            }
        }
        
        if (!configFile) {
            throw new Error(`Configuration file not found. Tried paths: ${possiblePaths.join(', ')}`);
        }
        
        const configContent = await app.vault.cachedRead(configFile);
        
        // Try multiple ways to extract JSON
        let config = null;
        
        // Method 1: Look for ```json block
        let jsonMatch = configContent.match(/```json\s*([\s\S]*?)\s*```/);
        if (jsonMatch) {
            try {
                config = JSON.parse(jsonMatch[1]);
            } catch (e) {
                // Continue to next method
            }
        }
        
        // Method 2: Look for ``` block without json specifier
        if (!config) {
            jsonMatch = configContent.match(/```\s*([\s\S]*?)\s*```/);
            if (jsonMatch) {
                try {
                    config = JSON.parse(jsonMatch[1]);
                } catch (e) {
                    // Continue to next method
                }
            }
        }
        
        // Method 3: Look for raw JSON (lines starting with {)
        if (!config) {
            const lines = configContent.split('\n');
            let jsonLines = [];
            let inJson = false;
            
            for (const line of lines) {
                if (line.trim().startsWith('{')) {
                    inJson = true;
                    jsonLines = [line];
                } else if (inJson && line.trim().startsWith('}')) {
                    jsonLines.push(line);
                    break;
                } else if (inJson) {
                    jsonLines.push(line);
                }
            }
            
            if (jsonLines.length > 0) {
                try {
                    config = JSON.parse(jsonLines.join('\n'));
                } catch (e) {
                    // Continue to error
                }
            }
        }
        
        if (!config) {
            throw new Error(`No valid JSON found in ${usedPath}. Content preview: ${configContent.substring(0, 200)}`);
        }
        
        // Validate required fields
        if (!config.apiKey) throw new Error("Missing apiKey in configuration");
        if (!config.model) throw new Error("Missing model in configuration"); 
        if (!config.apiUrl) throw new Error("Missing apiUrl in configuration");
        
        return config;
    } catch (error) {
        throw new Error(`Configuration error: ${error.message}`);
    }
}

// Function to call Claude API with retry logic
async function queryClaude(prompt, config, maxRetries = 3) {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            const requestBody = {
                model: config.model,
                max_tokens: config.maxTokens || 2000,
                messages: [{
                    role: 'user',
                    content: prompt
                }]
            };

            const response = await requestUrl({
                url: config.apiUrl,
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'x-api-key': config.apiKey,
                    'anthropic-version': '2023-06-01'
                },
                body: JSON.stringify(requestBody)
            });
            
            return response.json.content[0].text;
            
        } catch (error) {
            if (attempt === maxRetries) {
                return `Error calling Claude API after ${maxRetries} attempts: ${error.message}`;
            }
            
            const waitTime = Math.pow(2, attempt) * 1000;
            await new Promise(resolve => setTimeout(resolve, waitTime));
        }
    }
}

// Main execution with verbose error reporting
try {
    // Load configuration
    tR += "🔧 Loading configuration...\n";
    const config = await loadConfig();
    tR += "✅ Configuration loaded successfully\n\n";
    
    // Get the currently active note
    const activeFile = app.workspace.getActiveFile();
    if (!activeFile) {
        tR += "❌ No note is currently open. Please open a note first.\n";
    } else {
        tR += `📝 Analyzing note: "${activeFile.basename}"\n`;
        
        // Read the current note's content
        const currentNoteContent = await app.vault.cachedRead(activeFile);
        
        if (!currentNoteContent || currentNoteContent.trim().length === 0) {
            tR += "❌ The current note appears to be empty.\n";
        } else {
            tR += `📊 Note length: ${currentNoteContent.length} characters\n\n`;
            
            // Prompt user for their question
            const userQuestion = await tp.system.prompt("What would you like to know about this note?");
            
            if (!userQuestion) {
                tR += "❌ No question provided.\n";
            } else {
                tR += `❓ Question: ${userQuestion}\n\n`;
                tR += `⏳ Getting response from Claude (${config.model})...\n\n`;
                
                // Prepare the prompt for Claude
                const prompt = `Here is the content of a note titled "${activeFile.basename}":\n\n---\n${currentNoteContent}\n---\n\nQuestion: ${userQuestion}\n\nPlease provide a helpful and detailed answer based on the content of this note.`;
                
                // Call Claude API
                const response = await queryClaude(prompt, config);
                
                // Output the results
                tR += `# Analysis of "${activeFile.basename}"\n\n`;
                tR += `**Question:** ${userQuestion}\n\n`;
                tR += `**Answer:**\n\n${response}\n\n`;
                tR += `---\n*Generated on ${tp.date.now("YYYY-MM-DD HH:mm")}*`;
            }
        }
    }
} catch (error) {
    tR += `❌ Error: ${error.message}\n`;
    tR += `\n**Debug info:**\n`;
    tR += `- Error type: ${error.constructor.name}\n`;
    tR += `- Stack trace: ${error.stack}\n`;
}
%>
