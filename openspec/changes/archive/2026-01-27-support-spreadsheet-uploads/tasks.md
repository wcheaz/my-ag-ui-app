# Tasks: Support Spreadsheet Uploads

1.  **Implement CSV Support** <!-- id: 1 -->
    -   [x] 1.1 Install `papaparse`.
    -   [x] 1.2 Update `src/app/page.tsx` file input to accept `.csv`.
    -   [x] 1.3 Internal logic to read `.csv` and attach as text.
    -   [x] 1.4 Verify CSV upload works.

2.  **Implement Excel Support** <!-- id: 2 -->
    -   [x] 2.1 Install `xlsx`.
    -   [x] 2.2 Update `src/app/page.tsx` to accept `.xlsx`, `.xls`.
    -   [x] 2.3 Implement binary file reading for Excel.
    -   [x] 2.4 Use `xlsx` to convert first sheet to CSV text.
    -   [x] 2.5 Verify Excel upload works.

3.  **Cleanup & Polish** <!-- id: 3 -->
    -   [x] 3.1 Ensure error handling for malformed files.
    -   [x] 3.2 Check file size limits applicability to binary files.
