# Azure Functions API

This directory contains the Azure Functions backend for the Full Stack Demo application.

## Structure

```
api/
├── src/
│   └── functions/
│       ├── hello.js        # Sample HTTP trigger function
│       └── healthcheck.js  # Health check endpoint
├── host.json              # Function app configuration
└── package.json           # Node.js dependencies
```

## Functions

### hello
- **Method**: GET, POST
- **Route**: `/api/hello?name=YourName`
- **Description**: Returns a greeting message with timestamp

### healthcheck
- **Method**: GET
- **Route**: `/api/healthcheck`
- **Description**: Health check endpoint for monitoring

## Local Development

### Prerequisites
- Node.js 20.x
- Azure Functions Core Tools

### Install Dependencies
```bash
npm install
```

### Run Locally
```bash
npm start
```

The Functions will be available at:
- http://localhost:7071/api/hello
- http://localhost:7071/api/healthcheck

## Testing

```bash
# Test hello function
curl http://localhost:7071/api/hello?name=Developer

# Test health check
curl http://localhost:7071/api/healthcheck
```

## Deployment

Functions are automatically deployed via GitHub Actions when changes are pushed to the main branch.

## Configuration

Function app settings are managed in Terraform (`infra/main.tf`) and include:
- `FUNCTIONS_WORKER_RUNTIME`: node
- `WEBSITE_NODE_DEFAULT_VERSION`: ~20
- Application Insights connection string

## Adding New Functions

1. Create a new file in `src/functions/`
2. Use the Azure Functions programming model v4
3. Export the function using `app.http()` or other trigger types
4. Commit and push - GitHub Actions will deploy automatically
