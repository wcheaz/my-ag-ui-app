# Proposal: Download Procurement Codes

## Summary
Add a feature to allow users to download the list of generated procurement codes as a `.txt` file for offline use and record-keeping.

## Problem
Currently, generated procurement codes are only displayed in the UI. Users cannot easily export this list, making it difficult to save or share the results without manual copying.

## Solution
Implement a client-side download function in the `ProcurementCodes` component that generates a formatted `.txt` file containing all currently displayed codes and their descriptions.

## Impact
- **User Experience:** improved convenience for saving results.
- **Frontend:** modification to `src/components/procurement-codes.tsx`.
- **Backend:** None.
