# codebook


## This documentation explains the following:
- Explaination of each function
- Explanation of each input
- Explanation of each parameter
- Explanation of each variable



## Data Set 1 - Qicheng
### Explanation of code:
This script generates a sheet of patient visit by applying the patient-intake CSV and employee roster CSV, which includes multiple scheduled nurse visit based on triage severity(2-5), applying random lateness variation and assigning staff from the employee roster by the shift hours(3 shifts, morning, day, night). The generated dataset includes patient ID, room ID, severity level, total visit time, and assigned employee IDs. And finally output the file as CSV and ZIP.

Variables: 
| Category             | Variables / Objects                                                                                                                    |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **Libraries / Seed** | `library(tidyverse)`, `library(lubridate)`, `library(stringr)`, `library(truncnorm)`, `set.seed(42)`                                   |
| **Paths**            | `INFILE_PATIENT`, `INFILE_EMPLOYEE`, `OUTFILE`, `ZIPFILE`                                                                              |
| **Policy Constants** | `TARGET_MIN`, `ALLOW_MAX_MIN`, `JITTER_MEAN_FRACTION`, `JITTER_SD_FRACTION`                                                            |
| **Data Frames**      | `raw0`, `raw`, `nm_norm`, `patients`, `visits`, `visits_out`, `roster`                                                                 |
| **Renamed Columns**  | `Patient_ID`, `Room_Number`, `Severity`, `Date`, `Days`, `start_dt`, `stay_end`, `target_min`, `Time_In`, `Employee_ID`, `ShiftBucket` |


Input:
| File                                                                             | Purpose                             | Key Columns                                                                          |
| -------------------------------------------------------------------------------- | ----------------------------------- | ------------------------------------------------------------------------------------ |
| **Patient Intake CSV**<br>`Dataset_Locked_UCSF – Patient Intake.csv`             | Patient admission and severity info | `Patient_ID`, `Room_Number`, `Severity` (or look-alikes), `Date`, `Days` (default 3) |
| **Employee Information CSV**<br>`Dataset_Locked_UCSF – Employee Information.csv` | Nurse/employee roster with shifts   | `Employee_ID`, `Time In`, `Time Out`, optional `Shift/Code` (`M/D/N`)                |
| **Outputs**                                                                      | Generated visit dataset             | —                                      | `patient_visits.csv`, `patient_visits.zip`                                           |

Parameters:
| Parameter                | Description                                                                                                                  |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| **TARGET_MIN**           | Visit cadence (minutes) by Severity: `2 = 30`, `3 = 60`, `4 = 90`, `5 = 120`. Severity 1 excluded.                           |
| **ALLOW_MAX_MIN**        | Max allowed per-step jitter (12 min upper bound).                                                                            |
| **JITTER_MEAN_FRACTION** | Mean = 50 % of range (≈ 6 min if allow = 12).                                                                                |
| **JITTER_SD_FRACTION**   | SD = 25 % of range (≈ 3 min if allow = 12).                                                                                  |
| **Shift Buckets**        | `"0_8"` (00–07:59), `"8_16"` (08–15:59), `"16_24"` (16–23:59). Employees sampled from matching bucket or `all_ids` fallback. |


Functions:
| Function                                                                | Purpose                                                                            |     |                                                         |
| ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------- | --- | ------------------------------------------------------- |
| **.norm_names(x)**                                                      | Clean column names (trim, lowercase, snake-case).                                  |     |                                                         |
| **parse_dt(x)**                                                         | Parse date/time strings to UTC `POSIXct`.                                          |     |                                                         |
| **parse_time_hour(x)**                                                  | Extract hour (0–23) from numeric or text.                                          |     |                                                         |
| **to_bucket_from_bounds(h_start, h_end)**                               | Map start/end hours to shift buckets `0_8`, `8_16`, `16_24`.                       |     |                                                         |
| **to_bucket_from_code(code)**                                           | Convert shift codes (`M/D/N` or morning/day/night) to buckets.                     |     |                                                         |
| **get_employee_roster_from_csv(employee_csv)**                          | Build bucketed Employee ID lists from Time In/Out (uses synthetic IDs if missing). |     |                                                         |
| **rtrunc_minutes(n, allow_max_min, mean_frac, sd_frac)**                | Draw positive delay minutes from a truncated normal distribution.                  |     |                                                         |
| **make_schedule_plus_u12(start_dt, end_dt, target_min, allow_max_min)** | Generate visit timestamps (start → end) with randomized jitter.                    |     |                                                         |
| **%                                                                     |                                                                                    | %** | Null-or operator (returns `b` if `a` is missing/empty). |
| **pick(aliases, pool)**                                                 | Select first matching column alias.                                                |     |                                                         |
| **.sample_emp(bucket)**                                                 | Sample an `Employee_ID` from the bucket-specific roster.                           |     |                                                         |

Output:
| Column              | Description                                  |
| ------------------- | -------------------------------------------- |
| **Number_of_Visit** | Sequential visit count per patient.          |
| **Room_Number**     | Room / bed identifier.                       |
| **Patient_ID**      | Unique patient identifier.                   |
| **Severity**        | Triage level (2–5).                          |
| **Target_min**      | Target interval (minutes) for visit cadence. |
| **Time_In**         | Scheduled visit timestamp (UTC).             |
| **Employee_ID**     | Assigned nurse / staff ID.                   |

Example: 
| Number_of_Visit | Room_Number | Patient_ID | Severity | Target_min | Time_In             | Employee_ID |
| --------------- | ----------- | ---------- | -------- | ---------- | ------------------- | ----------- |
| 3               | A-203       | P000712    | 3        | 60         | 2025-10-18 09:47:31 | NUR014      |



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

| Category | Function | Description |
|-----------|-----------|-------------|
| **Name / Parse Helpers** | `norm_names(x)` | Trims whitespace, converts text to lowercase, and converts headers to snake_case for consistent naming. |
|  | `parse_dt(x)` | Robustly parses datetimes from multiple formats to standardize timestamps. |
|  | `parse_time_hour(x)` | Extracts integer hour (0–23) from numeric or string time formats. |
| **Shift Bucketing** | `to_bucket_from_bounds(h_start, h_end)` | Maps start and end hours to time buckets `"0_8"`, `"8_16"`, or `"16_24"`. |
|  | `to_bucket_from_code(code)` | Converts code labels such as “M/D/N” or “morning/day/night” into their corresponding shift buckets. |
| **Roster Building** | `get_employee_roster_from_csv(employee_csv)` | Reads the employee CSV file and creates bucketed employee ID lists using Time In/Out; falls back to synthetic IDs when data is missing. |
| **Utilities** | `%||%` | “Null-or” operator — returns the left-hand value unless it’s null, otherwise returns the right-hand value. |
|  | `pick(aliases, pool)` | Selects the first matching alias from a list of possible alternatives within a given pool. |
| **Scheduling** | `make_schedule_plus_u12(start_dt, end_dt, target_min, allow_max_min=12)` | Generates scheduled `Time_In` timestamps for each patient stay, adding random per-step jitter up to 12 minutes. |
| **Sampling & Attribution** | `.sample_emp(bucket)` | Randomly samples an `Employee_ID` from the roster corresponding to a given time bucket. |
|  | `extract_wing(emp_id)` | Infers the two-letter hospital wing from the employee ID (e.g., `"MDMW001"` → `"MW"`). |

## Functions - Cami

| Function(input) | Description | Variables | Output |
|------------|---------------------|----|------|
| **adjustTime(data)** | Adjusts the data type of the timestamps to enable us to subtract timestamps later on | `modify1`, `timeIN` |Adds columns to the data (where the timestamp is now datetime-type data insetad of a character string)|
| **interval_accuracy(data)** | Produces the normalized time accuracy of the intervals between check-ins for a patient. For example, if a patient needs to be checked in on every 2 hours (2-hr intervals), this function indicates how close (how accurate) the actual time intervals are to 2 hours when a caregiver comes to check in on the patient. Because there are different frequencies, or time intervals between check-ins for different patients, this value is normalized.| `prev_timeIN`, `difference`, `interval_deviation`, `normalized_intervalDiff`|Adds 3 columns of integers and 1 column of datetime to the data | 
| **late_min(data)** | Calculates how late caregivers are to check in on their patients, in units of minutes. The next expected timestamp is calculated by adding the time interval to the last recorded time check-in for a patient. The next actual timestamp is subtracted by the expected timestamp, and this difference is the number of minutes the caregiver is "late" to check-in on that patient.| `exp_time`, `late_by`|Adds a column of integers and datetime to the data|


Further exposition on **interval_accuracy(data)**:

- check-in time (`timeIN`) is subtracted by the previous check-in time for a patient which indicates how many minutes off you are from the expected frequency interval --> `difference`
- subtract the predetermined time interval of check-ins for that patient from this "difference" which tells us how much the actual time interval deviated from the expected time interval --> `interval_deviation`
- normalize the `interval_deviation` by dividing by the expected time interval
- if a caregiver is early, then they're not late and the `normalized_intervalDiff` will be negative. If this is the case, the `normalized_intervalDiff` will be set to 0


## Data Analysis - Jackson
### Explanation of code:

## UI - Zibin
### Explanation of code:
