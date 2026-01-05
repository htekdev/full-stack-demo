const { app } = require('@azure/functions');

app.http('healthcheck', {
    methods: ['GET'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        context.log('Health check endpoint called.');

        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                status: 'healthy',
                timestamp: new Date().toISOString(),
                service: 'Azure Functions API',
                version: '1.0.0'
            })
        };
    }
});
