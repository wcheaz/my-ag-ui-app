# Spec: Spreadsheet Support

## ADDED Requirements

### Requirement: The user can upload context files.
The chat interface MUST provide a mechanism to select text and spreadsheet files.

#### Scenario: User uploads a CSV file
Given the user is in the chat interface
When the user clicks the upload button
And selects a file named "data.csv"
Then the application reads the CSV content
And sends the content as text to the agent.

#### Scenario: User uploads an Excel file
Given the user is in the chat interface
When the user clicks the upload button
And selects a file named "data.xlsx"
Then the application parses the spreadsheet
And converts the visible data to a text representation (e.g., CSV)
And sends the content to the agent.

#### Scenario: File picker accepts multiple types
Given the user opens the file picker
Then it SHOULD accept `.txt`, `.csv`, `.xlsx`, and `.xls` files.
