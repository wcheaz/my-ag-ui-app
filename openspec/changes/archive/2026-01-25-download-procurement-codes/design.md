# Design: Download Procurement Codes

## Architecture
This feature will be implemented entirely on the client-side within the `ProcurementCodes` React component.

### Data Flow
1.  User clicks "Download" button.
2.  Component reads `state.procurement_codes`.
3.  Component formats data into a single string (e.g., "Code: Description\n").
4.  Component creates a `Blob` with MIME type `text/plain`.
5.  Component creates a temporary object URL and triggers a download via an anchor tag.

## Considerations
- **File Format:** Simple text file is requested. Format will be readable: `[Code] - [Description]`.
- **Browser Compatibility:** Standard HTML5 download attribute and Blob API will be used, supported by all modern browsers.
- **Empty State:** Button should be disabled or hidden if there are no codes.
