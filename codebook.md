# codebook


## This documentation explains the following:
- Explaination of each function
- Explanation of each input
- Explanation of each parameter
- Explanation of each variable



## Data Set 1 - Qicheng
### Explanation of code:

## Data Set 2 - Aras
### Explanation of code:
The script generates a visits dataset from a patient-intake CSV and an employee-roster CSV. It builds scheduled visit times per patient based on triage severity, assigns employees constrained by shift windows, applies lateness mutations under several rules (then caps delay), and writes the final table to CSV and ZIP.

### Variables
### Inputs
Patient intake CSV: Dataset_MediumSized_Locked - Patient Intake.csv (required).
Employee information CSV: Dataset_MediumSized_Locked - Employee Information.csv (optional—falls back to synthetic IDs if missing or malformed).

Expected columns in the CSV file
Patient: Patient_ID, Room_Number, Severity (or triage/level lookalikes), Date, Days (defaults to 3 if missing).
Employee: Employee_ID, Time In, Time Out, optional Shift/Code.
### Parameters
### Functions

## Functions - Cami
### Explanation of code:

## Data Analysis - Jackson
### Explanation of code:

## UI - Zibin
### Explanation of code:
