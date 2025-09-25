<%*
// Claude Task Summary Template
// Usage: Summarizes tasks for a specific person

// Function to load configuration from external file
async function loadConfig() {
    try {
        const configFile = app.vault.getAbstractFileByPath("claude-config.md");
        if (!configFile) {
            throw new Error("Configuration file 'claude-config.md' not found. Please create it first.");
        }
        
        const configContent = await app.vault.cachedRead(configFile);
        
        // Extract JSON from the markdown code block
        const jsonMatch = configContent.match(/```json\s*([\s\S]*?)\s*```/);
        if (!jsonMatch) {
            throw new Error("No JSON configuration found in claude-config.md");
        }
        
        const config = JSON.parse(jsonMatch[1]);
        
        // Validate required fields
        if (!config.apiKey || !config.model || !config.apiUrl) {
            throw new Error("Missing required configuration fields (apiKey, model, or apiUrl)");
        }
        
        return config;
    } catch (error) {
        throw new Error(`Configuration error: ${error.message}`);
    }
}

// Load configuration
let config;
try {
    config = await loadConfig();
} catch (error) {
    tR += `❌ ${error.message}`;
    return;
}

// Prompt user for person name
const personName = await tp.system.prompt("Who do you want to summarize tasks for?");

// Function to search for person-related content
async function findPersonTasks(person) {
    const files = app.vault.getMarkdownFiles();
    const relevantContent = [];
    
    for (const file of files) {
        try {
            const content = await app.vault.cachedRead(file);
            if (!content) continue;
            
            const lines = content.split('\n');
            
            // Find lines that mention the person
            lines.forEach((line, index) => {
                if (line.toLowerCase().includes(person.toLowerCase())) {
                    // Get context around the mention (3 lines before and after)
                    const contextStart = Math.max(0, index - 3);
                    const contextEnd = Math.min(lines.length, index + 4);
                    const context = lines.slice(contextStart, contextEnd).join('\n');
                    
                    relevantContent.push({
                        file: file.basename,
                        context: context,
                        line: line.trim()
                    });
                }
            });
        } catch (error) {
            console.log(`Error reading file ${file.path}:`, error);
        }
    }
    
    return relevantContent;
}

// Function to call Claude API with retry logic
async function queryClaude(prompt, maxRetries = config.maxRetries || 3) {
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
            
            // Success! Return the response
            return response.json.content[0].text;
            
        } catch (error) {
            console.log(`Attempt ${attempt} failed:`, error.message);
            
            // If this was the last attempt, return the error
            if (attempt === maxRetries) {
                return `Error calling Claude API after ${maxRetries} attempts: ${error.message}`;
            }
            
            // Wait before retrying (exponential backoff)
            const waitTime = Math.pow(2, attempt) * 1000; // 2s, 4s, 8s...
            console.log(`Waiting ${waitTime/1000} seconds before retry...`);
            await new Promise(resolve => setTimeout(resolve, waitTime));
        }
    }
}

// Find person-related tasks
const personContent = await findPersonTasks(personName);

if (personContent.length === 0) {
    tR += `No content found related to "${personName}"`;
} else {
    // Prepare context for Claude
    let context = `Based on these excerpts from my notes, summarize all tasks, responsibilities, and activities related to "${personName}":\n\n`;
    
    personContent.forEach((item, index) => {
        context += `### From note: ${item.file}\n${item.context}\n\n`;
    });
    
    context += `Please provide:
1. A summary of all tasks/activities where ${personName} is involved
2. Their role or responsibility in each
3. Any deadlines or important dates mentioned
4. Current status if indicated
Format this as a clear, organized summary.`;
    
    // Call Claude API
    const response = await queryClaude(context);
    
    // Output the results
    tR += `# Task Summary for ${personName}\n\n`;
    tR += `*Generated on ${tp.date.now("YYYY-MM-DD HH:mm")}*\n\n`;
    tR += `**Sources:** ${[...new Set(personContent.map(item => item.file))].map(file => `[[${file}]]`).join(', ')}\n\n`;
    tR += response;
}
%>