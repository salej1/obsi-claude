<%*
// Claude Timeline Query Template
// Usage: Insert this template and it will prompt for a subject

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

// Prompt user for query subject
const subject = await tp.system.prompt("What subject do you want a timeline for?");

// Function to search vault for relevant notes
async function findRelevantNotes(searchTerm) {
    const files = app.vault.getMarkdownFiles();
    const relevantNotes = [];
    
    for (const file of files) {
        try {
            const content = await app.vault.cachedRead(file);
            const fileName = file.basename;
            
            // Check if file name or content contains the search term
            if (fileName.toLowerCase().includes(searchTerm.toLowerCase()) || 
                (content && content.toLowerCase().includes(searchTerm.toLowerCase()))) {
                relevantNotes.push({
                    name: fileName,
                    path: file.path,
                    content: content || ""
                });
            }
        } catch (error) {
            console.log(`Error reading file ${file.path}:`, error);
        }
    }
    
    return relevantNotes;
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

// Find relevant notes
const notes = await findRelevantNotes(subject);

if (notes.length === 0) {
    tR += `No notes found related to "${subject}"`;
} else {
    // Prepare context for Claude (with size limit)
    let context = `Based on these notes from my Obsidian vault, create a timeline of events related to "${subject}":\n\n`;
    
    let totalLength = context.length;
    const maxContextLength = 8000; // Limit to ~8K characters to stay under token limits
    
    notes.forEach(note => {
        const noteContent = `## ${note.name}\n${note.content}\n\n`;
        if (totalLength + noteContent.length < maxContextLength) {
            context += noteContent;
            totalLength += noteContent.length;
        } else {
            // Truncate the note content if needed
            const remainingSpace = maxContextLength - totalLength - 100; // Leave some buffer
            if (remainingSpace > 100) {
                context += `## ${note.name}\n${note.content.substring(0, remainingSpace)}...\n\n`;
            }
        }
    });
    
    context += `Please create a chronological timeline of all events, dates, and milestones related to "${subject}" found in these notes. Format it clearly with dates and descriptions.`;
    
    // Call Claude API
    tR += `🔍 Found ${notes.length} relevant notes. Generating timeline...\n\n`;
    const response = await queryClaude(context);
    
    // Output the results
    tR += `# Timeline for ${subject}\n\n`;
    tR += `*Generated on ${tp.date.now("YYYY-MM-DD HH:mm")}*\n\n`;
    tR += `**Source Notes:** ${notes.map(n => `[[${n.name}]]`).join(', ')}\n\n`;
    tR += response;
}
%>