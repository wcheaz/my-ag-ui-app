# download-codes Specification

## Purpose
TBD - created by archiving change download-procurement-codes. Update Purpose after archive.
## Requirements
### Requirement: Download Codes
The application SHALL allow the user to download the generated procurement codes as a text file.

#### Scenario: User downloads codes
- **Requirement:** A "Download" button shall be available in the Procurement Codes card.
- **Requirement:** Clicking the button shall download a file named `procurement_codes.txt`.
- **Requirement:** The file content shall list each code and its description, one per line.
- **Requirement:** The button shall be disabled or hidden if no codes have been generated.

