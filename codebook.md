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
Library/seed: library(tidyverse), library(lubridate), library(stringr), set.seed(42).

Paths: INFILE_PATIENT, INFILE_EMPLOYEE, OUTFILE, ZIPFILE

Policy constants (see Parameters): TARGET_MIN, ALLOW_MAX_MIN, ALWAYS_LATE_IDS, SEV5_LATE_RANGE, MW_LATE_RANGE, PM4_6_MAX, LATE_CAP.

Intermediate data frames & columns:
raw0, raw, nm_norm, patients, visits, visits_out, roster.

Auto-detected/renamed columns: Patient_ID, Room_Number, Severity, Date, Days, start_dt, stay_end, target_min, Time_In, Employee_ID, Wing, Late_Min, Time_In_Final, ShiftBucket, etc.
### Inputs
Patient intake CSV: Dataset_MediumSized_Locked - Patient Intake.csv (required).
Employee information CSV: Dataset_MediumSized_Locked - Employee Information.csv (optional—falls back to synthetic IDs if missing or malformed).

Expected columns in the CSV file
Patient: Patient_ID, Room_Number, Severity (or triage/level lookalikes), Date, Days (defaults to 3 if missing).

Employee: Employee_ID, Time In, Time Out, optional Shift/Code.

### Parameters

Visit cadence by severity (minutes):
TARGET_MIN = c(2=30, 3=60, 4=90, 5=120) (Severity 1 excluded as severity 1 requires constant monitoring and wouldnt cause "lateness").

Per-step jitter: ALLOW_MAX_MIN = 12 (adds Uniform(0,12) minutes to each interval).

Lateness rules (additive, then capped):

ALWAYS_LATE_IDS = c("DSW002","MMW001") → +12–18 min.

SEV5_LATE_RANGE = c(6,12) if Severity == 5.

MW_LATE_RANGE = c(12,15) if employee wing is MW.

PM4_6_MAX = 15 extra minutes during 16:00–17:59.

LATE_CAP = 25 total minute cap.

Shift buckets: "0_8" (0–7:59), "8_16" (8–15:59), "16_24" (16–23:59).

### Functions

#### Name/parse helpers:

- norm_names(x): trims, lowercases, and snake-cases header names.

- parse_dt(x): robust datetime parser for several formats.

- parse_time_hour(x): extracts integer hour (0–23) from numeric or string times.

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
