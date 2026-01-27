# Proposal: Support Spreadsheet Uploads

## Goal
Extend the file upload capability to support CSVs and other spreadsheet formats (e.g., .xlsx). The agent should receive the content of these files as text/context to assist in generating procurement codes.

## Context
Currently, only `.txt` files are supported. Users often work with data in spreadsheets and converting them to text manually is inefficient.

## Implementation Strategy
1.  **Frontend Enhancements**:
    -   Update file picker to accept `.csv`, `.xlsx`, `.xls`.
    -   Integrate a library (e.g., `xlsx` or `papaparse`) to parse spreadsheet binaries/text in the browser.
    -   Format the parsed data (e.g., as Markdown tables or CSV text) before sending to the agent.

2.  **Phased Approach**:
    -   **Phase 1**: CSV support (using existing text reading or simple parsing).
    -   **Phase 2**: Excel/Spreadsheet support (requires binary parsing).

3.  **Backend**:
    -   No changes required; the agent continues to receive text.
