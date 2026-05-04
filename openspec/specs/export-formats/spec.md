# export-formats Specification

## Purpose
TBD - created by archiving change support-export-formats. Update Purpose after archive.
## Requirements
### Requirement: User can export codes in multiple formats.
The procurement code list MUST be exportable as CSV and Excel files.

#### Scenario: User exports as CSV
Given the user has generated procurement codes
When the user clicks "Download CSV"
Then the browser downloads a `.csv` file containing the codes and descriptions.

#### Scenario: User exports as Excel
Given the user has generated procurement codes
When the user clicks "Download Excel"
Then the browser downloads a `.xlsx` file containing the codes and descriptions.

