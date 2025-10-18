# codebook


## This documentation explains the following:
- Explanation of each variable


| **Variable Name**      | **Variable Type** | **Variable Definition**                                                                            |
| ---------------------- | ----------------- | -------------------------------------------------------------------------------------------------- |
| `INFILE_PATIENT`       | String Path       | File path to the patient intake CSV file containing admission and severity data.                   |
| `INFILE_EMPLOYEE`      | String Path       | File path to the employee roster CSV file containing employee shift and ID data.                   |
| `OUTFILE`              | String Path       | Destination file path for the generated patient visit dataset (CSV).                               |
| `ZIPFILE`              | String Path       | Destination file path for the compressed ZIP archive.                                              |
| `TARGET_MIN`           | Numeric Vector    | Defines target visit intervals by severity level: 2 = 30 min, 3 = 60 min, 4 = 90 min, 5 = 120 min. |
| `ALLOW_MAX_MIN`        | Integer           | Maximum allowed jitter (in minutes) for each visit interval (default = 12 min).                    |
| `JITTER_MEAN_FRACTION` | Numeric           | Mean fraction of jitter distribution, typically 0.5 × `ALLOW_MAX_MIN`.                             |
| `JITTER_SD_FRACTION`   | Numeric           | Standard deviation fraction of jitter distribution, typically 0.25 × `ALLOW_MAX_MIN`.              |
| `ALWAYS_LATE_IDS`      | Character Vector  | Employee IDs that are always late, adding an extra 12–18 minutes delay.                            |
| `SEV5_LATE_RANGE`      | Numeric Vector    | Range (6–12 minutes) of additional lateness for Severity 5 patients.                               |
| `MW_LATE_RANGE`        | Numeric Vector    | Range (12–15 minutes) of lateness for employees assigned to the Medical Wing (MW).                 |
| `PM4_6_MAX`            | Integer           | Maximum extra lateness (up to 15 minutes) for visits between 16:00–17:59.                          |
| `LATE_CAP`             | Integer           | Global upper bound (25 minutes) on total lateness accumulation.                                    |
| `raw0`                 | Data Frame        | Raw patient intake and employee data read directly from CSV files.                                 |
| `raw`                  | Data Frame        | Cleaned version of `raw0` after column normalization and filtering.                                |
| `nm_norm`              | Data Frame        | Data frame with normalized column names used for mapping and consistency.                          |
| `patients`             | Data Frame        | Processed patient intake dataset including calculated durations and severity.                      |
| `visits`               | Data Frame        | Expanded dataset containing scheduled visit records with time intervals.                           |
| `visits_out`           | Data Frame        | Final visit dataset ready for CSV export containing all key columns.                               |
| `roster`               | Data Frame        | Employee schedule data organized into shift buckets (`0_8`, `8_16`, `16_24`).                      |
| `Patient_ID`           | Character         | Unique identifier assigned to each patient.                                                        |
| `Room_Number`          | Character         | Room or bed assignment for the patient.                                                            |
| `Severity`             | Integer           | Triage severity level (values 2 – 5).                                                              |
| `Date`                 | Date              | Date of patient admission.                                                                         |
| `Days`                 | Integer           | Number of days the patient stays in the hospital (default = 3).                                    |
| `start_dt`             | POSIXct           | Start datetime of patient stay.                                                                    |
| `stay_end`             | POSIXct           | End datetime of patient stay.                                                                      |
| `Target_min`           | Integer           | Target interval (minutes) for patient visits based on severity.                                    |
| `Time_In`              | POSIXct           | Scheduled visit time for each patient.                                                             |
| `Employee_ID`          | Character         | Unique identifier for the assigned nurse or staff member.                                          |
| `Wing`                 | Character         | Hospital wing derived from the employee ID (e.g., “MW”).                                           |
| `Late_Min`             | Numeric           | Minutes a caregiver is late for a visit relative to the schedule.                                  |
| `Time_In_Final`        | POSIXct           | Adjusted visit time including lateness corrections.                                                |
| `ShiftBucket`          | Factor            | Categorical variable representing employee shift (`0_8`, `8_16`, `16_24`).                         |
| `Number_of_Visit`      | Integer           | Sequential counter representing the visit number per patient.                                      |
| `modify1`              | Character         | Ensuring proper formatting so we can convert into a datetime datatype later                        |
| `timeIN `              | POSIXct           | Converts time information into a datetime datatype                                                 |
| `prev_timeIN `         | POSIXct           | Identifies the last check-in time for a patient                                                    |
| `difference `          | Integer           | `timeIN` - `prev_timeIN`; indicates how many minutes off you are from the expected frequency interval|
| `interval_deviation `  | Integer           | `difference` - `Target_min`; indicates the difference or deviation from the expected time interval (in minutes) |
| `normalized_intervalDiff`| Integer         | `interval_deviation` / `Target_min`; normalizes `interval_deviation` to allow data comparison for different frequency intervals|
| `exp_time`             | POSIXct           | `prev_timeIN` + `Target_min`*60 ; expected timestamp for next check-in                             |
| `late_by `             | Integer           | `timeIN` - `exp_time` ; the difference (in minutes) from the expected time of check-in to actual check-in time|

