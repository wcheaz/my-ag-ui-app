# Design: File Upload Context

## Problem
Users need to provide long descriptions or existing documents to the agent. Copy-pasting is tedious.

## Solution
Implement a client-side file upload mechanism that reads `.txt` files and injects their content into the chat stream.

## Architectural Decisions
-   **Client-Side Reading**: We will use the browser's `FileReader` API to read the file content on the client. This avoids the need for a separate file upload API endpoint on the backend and keeps the agent stateless regarding file storage.
-   **Message Injection**: The content will be sent as a standard user message. This ensures the agent processes it using its existing NLP capabilities without needing a specialized "file handler" tool, adhering to the "as if inputted" requirement.
-   **UI Integration**: We will attempt to integrate the button into the `CopilotSidebar` via custom `actions` or by wrapping the prompt input if possible. If strict integration is difficult, we will place the button in a prominent location within the main content area or overlay.
