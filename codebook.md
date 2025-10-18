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

## Functions in R

### adjustTime(data)

Input: data

What it does: adjusts the dated, timestamp data to enable us to subtract timestamps later on

Output: an additional column to the data where the dated, timestamp data is now datetime type data (instead of a character string)

### interval_accuracy(data)

Input: data

What it does: produces the normalized time accuracy of the intervals between check-ins for a patient. For example, if a patient needs to be checked in on every 2 hours (2-hr intervals), this function indicates how close (how accurate) the actual time intervals are to 2 hours when a caregiver comes to check in on the patient. Because there are different frequencies, or time intervals between check-ins for different patients, this value is normalized. 

Output: an additional column to the data that contains this normalized time accuracy data (integer)

### late_min(data)
stuffffffffff

### Explanation of code:

## Data Analysis - Jackson
### Explanation of code:

## UI - Zibin
### Explanation of code:
