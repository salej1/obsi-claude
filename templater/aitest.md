<%*
// Function to load configuration
async function loadConfig() {
    try {
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

        let config = null;

        // Look for ```json block
        let jsonMatch = configContent.match(/```json\s*([\s\S]*?)\s*```/);
        if (jsonMatch) {
            try {
                config = JSON.parse(jsonMatch[1]);
            } catch (e) {
                // Continue to next method
            }
        }

        // Look for ``` block without json specifier
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

        // Look for raw JSON (lines starting with {)
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

        if (!config.apiKey) throw new Error("Missing apiKey in configuration");
        if (!config.model) throw new Error("Missing model in configuration");
        if (!config.apiUrl) throw new Error("Missing apiUrl in configuration");

        return config;
    } catch (error) {
        throw new Error(`Configuration error: ${error.message}`);
    }
}

try {
    const config = await loadConfig();
    const response = await requestUrl({
        url: config.apiUrl,
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'x-api-key': config.apiKey,
            'anthropic-version': '2023-06-01'
        },
        body: JSON.stringify({
            model: config.model,
            max_tokens: config.maxTokens || 100,
            messages: [{
                role: 'user',
                content: 'Hello! Please respond with just "API connection successful!"'
            }]
        })
    });
    
    tR += `✅ API Test Success!\n\n`;
    tR += `Response: ${response.json.content[0].text}`;
    tR += `\n\nStatus: ${response.status}`;
} catch (error) {
    tR += `❌ API Test Failed: ${error.message}`;
    if (error.status) {
        tR += `\nStatus Code: ${error.status}`;
    }
}
%>
