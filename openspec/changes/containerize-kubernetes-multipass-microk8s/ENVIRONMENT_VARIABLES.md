# Required Environment Variables for my-ag-ui-app

This document identifies all environment variables required for the my-ag-ui-app application to run properly in the Kubernetes deployment.

## Application Configuration Variables

### Node.js/Next.js Configuration
- **NODE_ENV**: Set to "production" for production runtime
- **PORT**: Application port, set to "3000" (default Next.js port)

## OpenAI Configuration Variables
These variables configure the OpenAI API connection for the LLM functionality.

### Sensitive Variables (stored in Kubernetes Secrets)
- **OPENAI_API_KEY**: API key for authenticating with OpenAI services
  - Required: Yes
  - Source: OpenAI API dashboard
  - Format: String (starts with "sk-")
  - Notes: Must be kept secret, used for all OpenAI API calls

- **OPENAI_BASE_URL**: Base URL for OpenAI API endpoint
  - Required: Yes
  - Source: OpenAI documentation or custom endpoint
  - Format: URL string (e.g., "https://api.openai.com/v1")
  - Notes: May be customized for enterprise deployments

- **OPENAI_MODEL**: Default OpenAI model to use for requests
  - Required: Yes
  - Source: OpenAI model list
  - Format: String (e.g., "gpt-4", "gpt-3.5-turbo")
  - Notes: Determines which model is used by default

## Procurement Agent Configuration Variables
These variables configure the LLM behavior for the procurement agent.

### Sensitive Variables (stored in Kubernetes Secrets)
- **EMBEDDING_MODEL**: Model to use for text embeddings
  - Required: Yes
  - Source: OpenAI embedding model list
  - Format: String (e.g., "text-embedding-ada-002")
  - Notes: Used for document vectorization and similarity search

### Non-Sensitive Variables (stored in Kubernetes ConfigMap)
- **LLM_MAX_TOKENS**: Maximum number of tokens for LLM responses
  - Required: Yes
  - Source: Application configuration
  - Format: Integer (e.g., "4096")
  - Notes: Controls response length and cost

- **LLM_CONTEXT_WINDOW**: Maximum context window size for the model
  - Required: Yes
  - Source: Model specifications
  - Format: Integer (e.g., "8192", "16384")
  - Notes: Must match the capabilities of the selected model

## Logging Configuration Variables
These variables configure application logging and monitoring.

### Sensitive Variables (stored in Kubernetes Secrets)
- **LOGFIRE_TOKEN**: Token for Logfire logging service
  - Required: Yes (if using Logfire)
  - Source: Logfire dashboard
  - Format: String (authentication token)
  - Notes: Only required if Logfire logging is enabled

## Variable Classification

### Security Classification
- **Highly Sensitive**: Requires storage in Kubernetes Secrets
  - OPENAI_API_KEY
  - OPENAI_BASE_URL
  - OPENAI_MODEL
  - EMBEDDING_MODEL
  - LOGFIRE_TOKEN

- **Non-Sensitive**: Can be stored in Kubernetes ConfigMaps
  - NODE_ENV
  - PORT
  - LLM_MAX_TOKENS
  - LLM_CONTEXT_WINDOW

### Required vs Optional
- **Required**: Application will not start without these variables
  - NODE_ENV
  - PORT
  - OPENAI_API_KEY
  - OPENAI_BASE_URL
  - OPENAI_MODEL
  - LLM_MAX_TOKENS
  - LLM_CONTEXT_WINDOW
  - EMBEDDING_MODEL

- **Conditionally Required**: Only needed for specific features
  - LOGFIRE_TOKEN (only if Logfire logging is used)

## Deployment Configuration

### Kubernetes Secrets
The following variables are configured in the `my-ag-ui-app-secrets` Kubernetes Secret:
- openai-api-key (from OPENAI_API_KEY)
- openai-base-url (from OPENAI_BASE_URL)
- openai-model (from OPENAI_MODEL)
- embedding-model (from EMBEDDING_MODEL)
- logfire-token (from LOGFIRE_TOKEN)

### Kubernetes ConfigMap
The following variables are configured in the `my-ag-ui-app-config` Kubernetes ConfigMap:
- llm-max-tokens (from LLM_MAX_TOKENS)
- llm-context-window (from LLM_CONTEXT_WINDOW)

### Environment Variable Injection
The deployment manifest injects these variables into the container:
- NODE_ENV (hardcoded as "production")
- PORT (hardcoded as "3000")
- All secret and ConfigMap values referenced above

## Validation Requirements

### Pre-deployment Validation
The deployment script should validate that:
1. All required environment variables are provided
2. Sensitive variables are properly base64 encoded for Kubernetes
3. Values are in the correct format (integers where expected, URLs where expected)

### Runtime Validation
The application should validate that:
1. All required environment variables are present at startup
2. Values are valid (e.g., API keys have correct format, URLs are properly formed)
3. Connections to external services (OpenAI, Logfire) work with provided credentials

## Default Values and Examples

### Production Defaults
```bash
NODE_ENV=production
PORT=3000
OPENAI_API_KEY=sk-your-openai-api-key-here
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4
LLM_MAX_TOKENS=4096
LLM_CONTEXT_WINDOW=8192
EMBEDDING_MODEL=text-embedding-ada-002
LOGFIRE_TOKEN=your-logfire-token-here
```

### Testing Defaults
```bash
NODE_ENV=development
PORT=3000
OPENAI_API_KEY=sk-test-key
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-3.5-turbo
LLM_MAX_TOKENS=1024
LLM_CONTEXT_WINDOW=4096
EMBEDDING_MODEL=text-embedding-ada-002
LOGFIRE_TOKEN=
```

## Notes for Deployment
1. **Security**: Never commit actual secret values to version control
2. **Environment**: Use different values for development, testing, and production
3. **Rotation**: Implement a process for rotating API keys and tokens
4. **Validation**: Test that the application starts correctly with all required variables
5. **Documentation**: Keep this document updated when new environment variables are added