# Design: Support Spreadsheet Uploads

## Problem
Users have procurement data in spreadsheets (CSV, Excel). Converting to TXT is manual work.

## Solution
Allow direct upload of `.csv`, `.xlsx`, `.xls` in the chat interface. Parse them on the client and send as text context.

## Architectural Decisions
1.  **Client-Side Parsing**:
    -   Use `papaparse` for robust CSV parsing (handling quotes, delimiters).
    -   Use `xlsx` (SheetJS) or similar for Excel files.
    -   **Rationale**: Keeps the backend simple and stateless. Avoids uploading sensitive files to a temporary server storage just for parsing.

2.  **Data Formatting for LLM**:
    -   CSV data is already text, but valid CSV string is good.
    -   Excel data should be converted to CSV format or Markdown table format to be token-efficient and readable by the LLM.
    -   **Decision**: Convert all spreadsheet data to a clean CSV string format when injecting into context.

3.  **Dependency Management**:
    -   Add `papaparse` and `xlsx` to `package.json`.
