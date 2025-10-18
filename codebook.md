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

| Category | Items | Description |
|-----------|--------|-------------|
| **Libraries / Seed** | `library(tidyverse)`, `library(lubridate)`, `library(stringr)`, `set.seed(42)` | Loads essential R packages for data manipulation, date handling, and string processing; sets a fixed random seed for reproducibility. |
| **Paths** | `INFILE_PATIENT`, `INFILE_EMPLOYEE`, `OUTFILE`, `ZIPFILE` | File path variables for input patient and employee data, output files, and compressed archives. |
| **Policy Constants (see Parameters)** | `TARGET_MIN`, `ALLOW_MAX_MIN`, `ALWAYS_LATE_IDS`, `SEV5_LATE_RANGE`, `MW_LATE_RANGE`, `PM4_6_MAX`, `LATE_CAP` | Configuration constants controlling policy thresholds such as minimum targets, allowable delays, specific late ID lists, and late-time ranges or caps. |
| **Intermediate Data Frames & Columns** | `raw0`, `raw`, `nm_norm`, `patients`, `visits`, `visits_out`, `roster` | Temporary or processed data tables created during pipeline execution, representing cleaned and transformed datasets. |
| **Auto-Detected / Renamed Columns** | `Patient_ID`, `Room_Number`, `Severity`, `Date`, `Days`, `start_dt`, `stay_end`, `target_min`, `Time_In`, `Employee_ID`, `Wing`, `Late_Min`, `Time_In_Final`, `ShiftBucket`, etc. | Column names automatically recognized or standardized for consistency across datasets, used in later transformations or analysis. |


### Inputs

| Category | Items | Description |
|-----------|--------|-------------|
| **Inputs** | `Dataset_MediumSized_Locked - Patient Intake.csv` | **Required.** Contains patient intake data used as the main dataset for processing. |
|  | `Dataset_MediumSized_Locked - Employee Information.csv` | **Optional.** Provides employee schedule and identification data; falls back to synthetic IDs if missing or invalid. |
| **Expected Columns – Patient CSV** | `Patient_ID`, `Room_Number`, `Severity` *(or triage/level lookalikes)*, `Date`, `Days` *(defaults to 3 if missing)* | Defines patient-specific attributes including ID, assigned room, condition severity, admission date, and stay duration. |
| **Expected Columns – Employee CSV** | `Employee_ID`, `Time In`, `Time Out`, optional `Shift`/`Code` | Specifies staff identifiers and work schedule information; optional shift or code column may describe work assignment type. |


### Parameters

| Category | Items | Description |
|-----------|--------|-------------|
| **Visit Cadence by Severity (minutes)** | `TARGET_MIN = c(2=30, 3=60, 4=90, 5=120)` | Defines target visit intervals (in minutes) based on patient severity level. Severity 1 is excluded, as it requires continuous monitoring and cannot be “late.” |
| **Per-Step Jitter** | `ALLOW_MAX_MIN = 12` | Adds random jitter of up to 12 minutes (`Uniform(0,12)`) to each visit interval for variability. |
| **Lateness Rule – Always Late IDs** | `ALWAYS_LATE_IDS = c("DSW002","MMW001") → +12–18 min` | Specific employees always incur an additional 12–18 minutes of lateness to simulate known delays. |
| **Lateness Rule – Severity 5 Patients** | `SEV5_LATE_RANGE = c(6,12)` | Adds 6–12 minutes of delay for patients with Severity 5 classification. |
| **Lateness Rule – MW Wing Employees** | `MW_LATE_RANGE = c(12,15)` | Adds 12–15 minutes of delay for employees assigned to the MW (Medical Wing). |
| **Time-Dependent Lateness Cap** | `PM4_6_MAX = 15` | Adds up to 15 extra minutes for visits occurring between 16:00–17:59. |
| **Overall Lateness Limit** | `LATE_CAP = 25` | Caps total accumulated lateness at 25 minutes to prevent excessive delay accumulation. |
| **Shift Buckets** | `"0_8"` (0–7:59), `"8_16"` (8–15:59), `"16_24"` (16–23:59) | Defines time-of-day groupings for employee shifts to categorize activity and lateness by period. |

### Functions

#### Name/parse helpers:

- norm_names(x): trims, lowercases, and snake-cases header names.

- parse_dt(x): robust datetime parser for several formats.

- parse_time_hour(x): extracts integer hour (0–23) from numeric or string times.

#### Shift bucketing:

- to_bucket_from_bounds(h_start, h_end): maps start/end hours to "0_8", "8_16", or "16_24".

- to_bucket_from_code(code): maps codes like M/D/N or morning/day/night to buckets.

#### Roster building:

- get_employee_roster_from_csv(employee_csv): reads employee CSV; derives bucketed ID lists using Time In/Out (falls back to synthetic IDs if needed).

#### Utilities:

- %||%: “null-or” operator.

- pick(aliases, pool): chooses the first matching alias from a set.

#### Scheduling:

- make_schedule_plus_u12(start_dt, end_dt, target_min, allow_max_min=12): builds a series of scheduled Time_In timestamps per patient stay window.

#### Sampling & attribution:

- .sample_emp(bucket): samples an Employee_ID from the bucket-specific roster.

- extract_wing(emp_id): infers the two-letter wing from the last letters before trailing digits (e.g., "MDMW001" → "MW").

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
