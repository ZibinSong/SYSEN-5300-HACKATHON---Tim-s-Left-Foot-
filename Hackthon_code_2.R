#Hackathon_code_2
#Hackathon_code_2
# =========================================
# Patient Visits Generator (with real Employee_IDs from CSV)
# =========================================

# install.packages(c("tidyverse","lubridate","stringr","readxl"), dependencies = TRUE)  # run once
# =========================================
# Patient Visits Generator (Time In only) + Lateness Mutations
# =========================================

library(tidyverse)
library(lubridate)
library(stringr)

set.seed(42)

# =========================
# Paths
# =========================
INFILE_PATIENT  <- "/cloud/project/Dataset_MediumSized_Locked - Patient Intake.csv"
INFILE_EMPLOYEE <- "/cloud/project/Dataset_MediumSized_Locked - Employee Information.csv"
OUTFILE <- "/cloud/project/MedSize_visits.csv"
ZIPFILE <- "/cloud/project/MedSize_visits.zip"

# =========================
# Policy
# =========================
TARGET_MIN    <- c(`2`=30, `3`=60, `4`=90, `5`=120)  # minutes (Severity 1 excluded)
ALLOW_MAX_MIN <- 12                                   # + Uniform(0,12) minutes each step

# Lateness mutation rules (all additive then capped at 25)
ALWAYS_LATE_IDS <- c("DSW002","MMW001")               # always +12–18 minutes
SEV5_LATE_RANGE <- c(6, 12)                           # +6–12 if Severity==5
MW_LATE_RANGE   <- c(12, 15)                          # +12–15 if Wing=="MW"
PM4_6_MAX       <- 15                                 # up to +15 during 16:00–18:00
LATE_CAP        <- 25                                 # total cap

# =========================
# Helpers
# =========================
.norm_names <- function(x){
  x |>
    stringr::str_trim() |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("[^a-z0-9]+", "_")
}

parse_dt <- function(x){
  suppressWarnings(lubridate::parse_date_time(
    x,
    orders = c("Y-m-d H:M:S","m/d/Y H:M:S","Y/m/d H:M:S","Y-m-d H:M","m/d/Y H:M","Y/m/d H:M"),
    quiet  = TRUE
  ))
}

# --- vectorized time-of-day parsing to integer hour [0,24)
parse_time_hour <- function(x){
  if (is.numeric(x)) {
    h <- suppressWarnings(as.integer(x)) %% 24L
    h[is.na(x)] <- NA_integer_
    return(h)
  }
  s <- as.character(x)
  s <- trimws(s)
  s[s == ""] <- NA_character_
  h <- suppressWarnings(as.integer(stringr::str_extract(s, "^[0-9]{1,2}")))
  h <- h %% 24L
  h[is.na(s)] <- NA_integer_
  h
}

# bounds->bucket
to_bucket_from_bounds <- function(h_start, h_end){
  h_start <- as.integer(h_start); h_end <- as.integer(h_end)
  h_end2 <- ifelse(!is.na(h_start) & !is.na(h_end) & h_start == 16L & h_end == 0L, 24L, h_end)
  out <- ifelse(h_start == 0L  & h_end2 == 8L,  "0_8",
                ifelse(h_start == 8L  & h_end2 == 16L, "8_16",
                       ifelse(h_start == 16L & h_end2 == 24L, "16_24", NA_character_)))
  out
}

# code->bucket (M/D/N)
to_bucket_from_code <- function(code){
  c <- tolower(trimws(as.character(code)))
  c[c == ""] <- NA_character_
  out <- ifelse(!is.na(c) & c %in% c("m","morning"), "0_8",
                ifelse(!is.na(c) & c %in% c("d","day"),     "8_16",
                       ifelse(!is.na(c) & c %in% c("n","night"),   "16_24", NA_character_)))
  out
}

# Build roster buckets strictly from employee file Time In / Time out (with code as backup)
get_employee_roster_from_csv <- function(employee_csv){
  fallback_ids <- sprintf("NUR%03d", 1:60)
  if (!file.exists(employee_csv)) {
    warning(sprintf("Couldn't find '%s'; using synthetic roster for all buckets.", basename(employee_csv)))
    return(list(`0_8`=fallback_ids, `8_16`=fallback_ids, `16_24`=fallback_ids, all_ids=fallback_ids))
  }
  emp_raw <- suppressMessages(readr::read_csv(employee_csv, show_col_types = FALSE))
  if (nrow(emp_raw) == 0) {
    warning("Employee file is empty; using synthetic roster for all buckets.")
    return(list(`0_8`=fallback_ids, `8_16`=fallback_ids, `16_24`=fallback_ids, all_ids=fallback_ids))
  }
  nm <- .norm_names(names(emp_raw))
  
  id_idx    <- which(nm %in% c("employee_id","employeeid","emp_id","employee_number","id"))[1]
  tin_idx   <- which(nm %in% c("time_in","timein","time_in_", "start_time","start","in"))[1]
  tout_idx  <- which(nm %in% c("time_out","timeout","time_out_", "end_time","end","out"))[1]
  code_idx  <- which(nm %in% c("shift","shift_code","shift_label","code"))[1]
  
  if (is.na(id_idx) || is.na(tin_idx) || is.na(tout_idx)) {
    warning("Couldn't find Employee ID and Time In/Out columns; using synthetic roster for all buckets.")
    return(list(`0_8`=fallback_ids, `8_16`=fallback_ids, `16_24`=fallback_ids, all_ids=fallback_ids))
  }
  
  df <- tibble(
    Employee_ID = emp_raw[[id_idx]] |> as.character() |> trimws(),
    TimeInH     = parse_time_hour(emp_raw[[tin_idx]]),
    TimeOutH    = parse_time_hour(emp_raw[[tout_idx]]),
    ShiftCode   = if (is.na(code_idx)) NA_character_ else emp_raw[[code_idx]]
  ) |>
    filter(!is.na(Employee_ID) & Employee_ID != "")
  
  df <- df |>
    mutate(
      Bucket_bounds = to_bucket_from_bounds(TimeInH, TimeOutH),
      Bucket_code   = to_bucket_from_code(ShiftCode),
      Bucket        = if_else(!is.na(Bucket_bounds), Bucket_bounds, Bucket_code)
    )
  
  b0 <- df |> filter(Bucket == "0_8")   |> pull(Employee_ID) |> unique()
  b1 <- df |> filter(Bucket == "8_16")  |> pull(Employee_ID) |> unique()
  b2 <- df |> filter(Bucket == "16_24") |> pull(Employee_ID) |> unique()
  all_ids <- unique(c(b0, b1, b2, df |> filter(is.na(Bucket)) |> pull(Employee_ID)))
  
  if (!length(b0)) warning("No employees with Time In/Out mapped to 0–8 (M).")
  if (!length(b1)) warning("No employees with Time In/Out mapped to 8–16 (D).")
  if (!length(b2)) warning("No employees with Time In/Out mapped to 16–24 (N).")
  
  list(`0_8`=b0, `8_16`=b1, `16_24`=b2, all_ids=all_ids)
}

roster <- get_employee_roster_from_csv(INFILE_EMPLOYEE)

`%||%` <- function(a,b) if (!is.null(a) && length(a) && !is.na(a)) a else b
pick <- function(aliases, pool) { intersect(aliases, pool)[1] %||% NA_character_ }

# =========================
# Visit schedule generator (defines Time_In series)
# =========================
make_schedule_plus_u12 <- function(start_dt, end_dt, target_min, allow_max_min = 12){
  if (is.na(start_dt) || is.na(end_dt) || end_dt <= start_dt) return(list())
  t <- start_dt
  out <- c(t)
  repeat {
    step_min <- target_min + runif(1, 0, allow_max_min)
    t <- t + minutes(round(step_min))
    if (t >= end_dt) break
    out <- c(out, t)
  }
  out
}

# =========================
# 1) Load & clean intake (auto-detect headers)
# =========================
stopifnot(file.exists(INFILE_PATIENT))
raw0 <- readr::read_csv(INFILE_PATIENT, show_col_types = FALSE)

# normalize headers
nm_norm <- names(raw0) |>
  stringr::str_trim() |>
  stringr::str_replace_all("\\s+", "_") |>
  stringr::str_replace_all("\\.+", "_") |>
  tolower()
names(raw0) <- nm_norm
raw0 <- dplyr::select(raw0, !dplyr::starts_with("unnamed"))

# alias mapping
pid_col   <- pick(c("patient_id","patient__id","patient_number","patientnum","patientno","patientid"), names(raw0))
room_col  <- pick(c("room_number","room_no","room","roomnum","roomnumber"), names(raw0))
sev_col   <- pick(c("severity","serverity","severity_level","patient_severity","triage","triage_level","triagelevel"), names(raw0))
date_col  <- pick(c("date","admit_date","admission_date","admission_datetime","datetime","start_dt","visit_datetime"), names(raw0))
days_col  <- pick(c("days","length_of_stay","los","stay_days","staylength","day"), names(raw0))

# rename what we can
raw <- raw0
if (!is.na(pid_col))   names(raw)[names(raw) == pid_col]   <- "Patient_ID"
if (!is.na(room_col))  names(raw)[names(raw) == room_col]  <- "Room_Number"
if (!is.na(sev_col))   names(raw)[names(raw) == sev_col]   <- "Severity"
if (!is.na(date_col))  names(raw)[names(raw) == date_col]  <- "Date"
if (!is.na(days_col))  names(raw)[names(raw) == days_col]  <- "Days"

# auto-detect Severity if still missing
if (!"Severity" %in% names(raw)) {
  candidates <- names(raw0)[stringr::str_detect(names(raw0), "sev|triage|level")]
  if (length(candidates) == 0) candidates <- names(raw0)
  best <- NA_character_; best_score <- -Inf
  for (c in candidates) {
    v <- suppressWarnings(as.integer(as.character(raw0[[c]])))
    score <- mean(v %in% 1:5, na.rm = TRUE)
    if (!is.nan(score) && score > best_score) { best_score <- score; best <- c }
  }
  if (!is.na(best) && best_score >= 0.6) {
    raw$Severity <- suppressWarnings(as.integer(as.character(raw0[[best]])))
    message(sprintf("⚙️  Using column '%s' as Severity (%.0f%% in 1..5).", best, 100*best_score))
  } else {
    cat("\n---- Headers in your CSV ----\n"); print(names(raw0))
    stop("Couldn't find a Severity-like column. Please rename your triage/severity column to 'Severity'.")
  }
}

# required fields
if (!"Patient_ID"  %in% names(raw))  stop("Missing Patient_ID.")
if (!"Room_Number" %in% names(raw))  stop("Missing Room_Number.")
if (!"Date"        %in% names(raw))  stop("Missing Date.")
if (!"Days"        %in% names(raw))  { warning("Missing Days; defaulting to 3."); raw$Days <- 3L }

# parse & coerce
patients <- raw |>
  mutate(
    Severity = suppressWarnings(as.integer(Severity)),
    Days     = suppressWarnings(as.integer(if_else(is.na(Days), 3L, Days))),
    start_dt = parse_dt(Date)
  )

# keep severities 2–5 and compute window + target
patients <- patients |>
  filter(Severity %in% 2:5) |>
  mutate(
    target_min = TARGET_MIN[as.character(Severity)],
    stay_end   = start_dt + days(Days)
  )

# =========================
# 2) Expand into visit rows (Time_In only)
# =========================
visits <- patients |>
  rowwise() |>
  mutate(Time_In_list = list(make_schedule_plus_u12(start_dt, stay_end, target_min, ALLOW_MAX_MIN))) |>
  ungroup() |>
  select(Patient_ID, Room_Number, Severity, target_min, Time_In_list) |>
  unnest(Time_In_list, names_repair = "minimal") |>
  rename(Time_In = Time_In_list) |>
  arrange(Patient_ID, Time_In)

# =========================
# Assign Employee_ID strictly within recorded shift windows
# =========================
visits <- visits |>
  mutate(
    .hour = lubridate::hour(Time_In),
    ShiftBucket = dplyr::case_when(
      .hour >= 0  & .hour < 8  ~ "0_8",   # Morning (M)
      .hour >= 8  & .hour < 16 ~ "8_16",  # Day (D)
      TRUE                    ~ "16_24"   # Night (N)
    )
  )

.sample_emp <- function(bucket) {
  pool <- switch(bucket,
                 "0_8"   = roster[["0_8"]],
                 "8_16"  = roster[["8_16"]],
                 "16_24" = roster[["16_24"]],
                 character(0)
  )
  if (length(pool) == 0) pool <- roster[["all_ids"]]
  sample(pool, 1)
}

visits$Employee_ID <- vapply(visits$ShiftBucket, .sample_emp, character(1))

# =========================
# Lateness Mutations (+ cap at 25 minutes)
# =========================
# Wing is inferred from the last two letters immediately before the digits in Employee_ID.
extract_wing <- function(emp_id) {
  # take the last two letters before trailing digits, e.g., "MDMW001" -> "MW", "DSW002" -> "SW"
  m <- stringr::str_match(emp_id, "([A-Za-z]{2})(\\d+)$")
  wing <- ifelse(is.na(m[,2]), NA_character_, toupper(m[,2]))
  wing
}

visits <- visits |>
  mutate(
    Wing = extract_wing(Employee_ID),
    
    # Base zero vector
    Late_Min_base = 0,
    
    # Rule 1: specific employees always late 12–18
    Late_emp = if_else(Employee_ID %in% ALWAYS_LATE_IDS,
                       runif(n(), 12, 18), 0),
    
    # Rule 2: triage level severity 5 gets +6–12
    Late_sev5 = if_else(Severity == 5L, runif(n(), SEV5_LATE_RANGE[1], SEV5_LATE_RANGE[2]), 0),
    
    # Rule 3: Wing MW usually late +12–15
    Late_mw = if_else(Wing == "MW", runif(n(), MW_LATE_RANGE[1], MW_LATE_RANGE[2]), 0),
    
    # Rule 4: 16:00–18:00 everyone has higher chance to be late up to +15
    .hh = hour(Time_In),
    .mm = minute(Time_In),
    in_4to6pm = (.hh == 16L | .hh == 17L),  # 16:00–17:59
    Late_pm = if_else(in_4to6pm, runif(n(), 0, PM4_6_MAX), 0),
    
    # Sum & cap
    Late_Min_raw = Late_Min_base + Late_emp + Late_sev5 + Late_mw + Late_pm,
    Late_Min = pmin(LATE_CAP, round(Late_Min_raw)),
    
    # Mutated time
    Time_In_Final = Time_In + minutes(Late_Min)
  ) |>
  select(-Late_Min_base, -.hh, -.mm, -in_4to6pm)

# =========================
# 3) Final output
# =========================
visits_out <- visits |>
  group_by(Patient_ID) |>
  arrange(Time_In, .by_group = TRUE) |>
  mutate(Number_of_Visit = row_number()) |>
  ungroup() |>
  transmute(
    Number_of_Visit,
    Room_Number,
    Patient_ID,
    Severity,
    Target_min = target_min,
    # keep both the scheduled and the mutated timestamps
    Time_In_Scheduled = format(Time_In, "%Y-%m-%d %H:%M:%S"),
    Late_Min,                       # total minutes of delay (capped at 25)
    Time_In = format(Time_In_Final, "%Y-%m-%d %H:%M:%S"),
    Employee_ID,
    Wing
  )

# =========================
# 4) Save (CSV + ZIP)
# =========================
readr::write_csv(visits_out, OUTFILE)
zip(zipfile = ZIPFILE, files = OUTFILE, flags = "-j")

cat("✅ Wrote:", OUTFILE, " | rows:", nrow(visits_out), "\n")
cat("📦 Zipped:", ZIPFILE, "\n")
print(head(visits_out, 10))
