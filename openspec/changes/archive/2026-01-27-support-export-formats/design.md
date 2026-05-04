# Design: Support Export Formats

## UI Design
Wait, `ProcurementCodes` is a simple component. Adding a full dropdown component (`Select` or custom menu) might be overkill if we don't have a UI library for it handy (we have `@copilotkit/react-ui` but maybe not a generic Popover).

**Simple Approach**:
Just add two more buttons (icons) next to the download button, or change the button to a row of small icon buttons:
`[TXT] [CSV] [XLS]`

Actually, looking at the code, it uses Tailwind. I will implement a simple inline group of buttons for simplicity and usability.

## Logic
1.  **CSV**:
    -   Header: `Code, Description`
    -   Content: Map state items.
    -   Use `Blob` with `text/csv`.

2.  **Excel**:
    -   Use `xlsx.utils.json_to_sheet([{ "Code": "...", "Description": "..." }])`
    -   Use `xlsx.writeFile` to trigger download.
