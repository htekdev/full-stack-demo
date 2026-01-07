const { app } = require('@azure/functions');

app.http('hello', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        context.log('HTTP trigger function processed a request.');

        const name = request.query.get('name') || 'World';
        
        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                message: `Hello, ${name}! This response comes from Azure Functions.`,
                timestamp: new Date().toISOString(),
                environment: process.env.AZURE_FUNCTIONS_ENVIRONMENT || 'local',
                version: '1.0.0'
            })
        };
    }
});
