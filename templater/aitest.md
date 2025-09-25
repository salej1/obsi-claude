<%*
const API_KEY = "YOUR-API-KEY"; // Replace with your actual key
const API_URL = "https://api.anthropic.com/v1/messages";

try {
    const response = await requestUrl({
        url: API_URL,
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'x-api-key': API_KEY,
            'anthropic-version': '2023-06-01'
        },
        body: JSON.stringify({
            model: 'claude-3-5-sonnet-20241022',
            max_tokens: 100,
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
