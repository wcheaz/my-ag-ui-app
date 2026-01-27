# Proposal: Support Export Formats

## Goal
Enable users to export generated procurement codes as CSV and Excel files, in addition to the existing Text format.

## Context
Users currently can only download a simple `.txt` file. For reporting and integration with other systems, structured formats like CSV and Excel are preferred.

## Implementation Strategy
1.  **UI Updates**:
    -   Replace the single "Download Codes" button with a "Download" dropdown or split button menu.
    -   Options: "Download as Text", "Download as CSV", "Download as Excel".

2.  **Logic**:
    -   **CSV**: Use `papaparse` (already available) or manual string construction.
    -   **Excel**: Use `xlsx` (already available) `utils.json_to_sheet` to create a workbook and download it.
