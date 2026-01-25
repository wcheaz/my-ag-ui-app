# Spec: File Context

## ADDED Requirements

### Requirement: The user can upload text files to the chat.
The chat interface MUST provide a mechanism (e.g., a "+" button) to select a file from the user's device.

#### Scenario: User uploads a valid text file
Given the user is in the chat interface
When the user clicks the "+" button
And selects a file named "specs.txt" containing "Material: Steel"
Then the application reads the file content
And sends the text "Material: Steel" (or similar context) to the agent as a user message.

#### Scenario: User is prompted for .txt files
Given the user triggers the file upload
Then the file picker SHOULD default to accepting `.txt` files.
