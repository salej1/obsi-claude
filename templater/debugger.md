<%*
// Debug template to identify issues

tR += "🔍 **Claude Integration Debug Report**\n\n";

// Check if config file exists
try {
    tR += "**Step 1: Checking config file...**\n";
    const configFile = app.vault.getAbstractFileByPath("config/claude-config.md");
    if (!configFile) {
        tR += "❌ Config file not found at 'config/claude-config.md'\n";
        
        // List all files in config folder to help debug
        const configFolder = app.vault.getAbstractFileByPath("config");
        if (configFolder && configFolder.children) {
            tR += "Files in config folder:\n";
            configFolder.children.forEach(file => {
                tR += `  - ${file.name}\n`;
            });
        } else {
            tR += "❌ Config folder doesn't exist or is empty\n";
        }
    } else {
        tR += `✅ Config file found: ${configFile.path}\n`;
        
        // Try to read the config file
        try {
            const configContent = await app.vault.cachedRead(configFile);
            tR += `✅ Config file read successfully (${configContent.length} characters)\n`;
            
            // Show first 200 characters of config
            tR += `Config preview: ${configContent.substring(0, 200)}...\n\n`;
            
            // Try to extract JSON
            const jsonMatch = configContent.match(/```json\s*([\s\S]*?)\s*```/);
            if (!jsonMatch) {
                tR += "❌ No JSON block found in config file\n";
            } else {
                tR += "✅ JSON block found\n";
                try {
                    const config = JSON.parse(jsonMatch[1]);
                    tR += `✅ JSON parsed successfully\n`;
                    tR += `API Key: ${config.apiKey ? config.apiKey.substring(0, 10) + '...' : 'MISSING'}\n`;
                    tR += `Model: ${config.model || 'MISSING'}\n`;
                    tR += `API URL: ${config.apiUrl || 'MISSING'}\n`;
                } catch (parseError) {
                    tR += `❌ JSON parsing failed: ${parseError.message}\n`;
                    tR += `JSON content: ${jsonMatch[1]}\n`;
                }
            }
        } catch (readError) {
            tR += `❌ Failed to read config file: ${readError.message}\n`;
        }
    }
} catch (error) {
    tR += `❌ Error checking config: ${error.message}\n`;
}

tR += "\n**Step 2: Checking current note...**\n";
const activeFile = app.workspace.getActiveFile();
if (!activeFile) {
    tR += "❌ No active file\n";
} else {
    tR += `✅ Active file: ${activeFile.name}\n`;
    tR += `✅ File path: ${activeFile.path}\n`;
}

tR += "\n**Step 3: Testing requestUrl function...**\n";
try {
    // Test a simple HTTP request to verify requestUrl works
    const testResponse = await requestUrl({
        url: "https://httpbin.org/get",
        method: "GET"
    });
    tR += `✅ requestUrl function works (status: ${testResponse.status})\n`;
} catch (error) {
    tR += `❌ requestUrl function failed: ${error.message}\n`;
}

tR += "\n**Debugging complete!**\n";
%>
