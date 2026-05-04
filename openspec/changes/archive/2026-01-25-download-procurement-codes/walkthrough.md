# Walkthrough: Download Procurement Codes

## Changes
I have implemented the ability to download generated procurement codes as a `.txt` file.

### Backend
None.

### Frontend
- Modified `src/components/procurement-codes.tsx` to:
    - Add a `handleDownload` function that converts the `procurement_codes` array to a formatted string.
    - Uses `Blob` and `URL.createObjectURL` to trigger a client-side download.
    - Add a "Download Codes" button that is conditionally rendered only when codes exist.

## Verification
### Automated Tests
- N/A (Client-side logic)

### Manual Verification
1. **Generate Codes**: Ask the agent to generate procurement codes.
2. **Download**: Click the new "Download Codes" button.
3. **Verify File**: Check the downloaded `procurement_codes.txt` file contains the codes "Code - Description".
4. **Empty State**: Clear the codes (using the 'x' buttons) and verify the "Download Codes" button disappears.
