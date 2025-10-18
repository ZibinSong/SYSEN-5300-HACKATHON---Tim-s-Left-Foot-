# =========================================
# Patient Visits Generator (uses employee Time In/Time out for shifts)
# =========================================

# install.packages(c("tidyverse","lubridate","stringr","truncnorm"), dependencies = TRUE)  # run once

library(tidyverse)
library(lubridate)
library(stringr)
library(truncnorm)

set.seed(42)

# =========================
# Paths
# =========================
INFILE_PATIENT  <- "/cloud/project/Dataset_Locked_UCSF - Patient Intake.csv"
INFILE_EMPLOYEE <- "/cloud/project/Dataset_Locked_UCSF - Employee Information.csv"
OUTFILE <- "/cloud/project/patient_visits.csv"
ZIPFILE <- "/cloud/project/patient_visits.zip"

# =========================
# Policy
# =========================
TARGET_MIN    <- c(`2`=30, `3`=60, `4`=90, `5`=120)  # minutes (Severity 1 excluded)
ALLOW_MAX_MIN <- 12                                   # allowed jitter (minutes)

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
  # Parse then force to UTC POSIXct to avoid tz() warnings downstream
  dt <- suppressWarnings(lubridate::parse_date_time(
    x,
    orders = c("Y-m-d H:M:S","m/d/Y H:M:S","Y/m/d H:M:S","Y-m-d H:M","m/d/Y H:M","Y/m/d H:M"),
    quiet  = TRUE
  ))
  lubridate::force_tz(dt, tzone = "UTC")
}

# --- FIX: fully vectorized time-of-day parsing to integer hour [0,24)
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

# --- FIX: vectorized bounds->bucket
to_bucket_from_bounds <- function(h_start, h_end){
  h_start <- as.integer(h_start); h_end <- as.integer(h_end)
  h_end2 <- ifelse(!is.na(h_start) & !is.na(h_end) & h_start == 16L & h_end == 0L, 24L, h_end)
  out <- ifelse(h_start == 0L  & h_end2 == 8L,  "0_8",
                ifelse(h_start == 8L  & h_end2 == 16L, "8_16",
                       ifelse(h_start == 16L & h_end2 == 24L, "16_24", NA_character_)))
  out
}

# --- FIX: vectorized code->bucket (M/D/N)
to_bucket_from_code <- function(code){
  c <- tolower(trimws(as.character(code)))
  c[c == ""] <- NA_character_
  out <- ifelse(!is.na(c) & c %in% c("m","morning"), "0_8",
                ifelse(!is.na(c) & c %in% c("d","day"),     "8_16",
                       ifelse(!is.na(c) & c %in% c("n","night"),   "16_24", NA_character_)))
  out
}

# --- True truncated-normal jitter helpers using truncnorm
# Mean/SD define the *underlying* normal before truncation to [0, ALLOW_MAX_MIN]
JITTER_MEAN_FRACTION <- 0.5   # mean at 50% of range (e.g., 6 when max=12)
JITTER_SD_FRACTION   <- 0.25  # sd at 25% of range (e.g., 3 when max=12)

rtrunc_minutes <- function(n, allow_max_min, mean_frac = JITTER_MEAN_FRACTION, sd_frac = JITTER_SD_FRACTION){
  mu <- allow_max_min * mean_frac
  sd <- allow_max_min * sd_frac
  truncnorm::rtruncnorm(n, a = 0, b = allow_max_min, mean = mu, sd = sd)
}

# --- Normal-based schedule generator (two-sided truncation, POSIXct UTC, fractional minutes ok)
make_schedule_plus_u12 <- function(start_dt, end_dt, target_min, allow_max_min) {
  # Force inputs to POSIXct UTC
  start_dt <- lubridate::as_datetime(start_dt, tz = "UTC")
  end_dt   <- lubridate::as_datetime(end_dt,   tz = "UTC")
  
  times <- start_dt
  cur   <- start_dt
  max_steps <- 10000L
  step <- 0L
  
  while (TRUE) {
    # draw truncated-normal jitter in minutes (bounded on both ends)
    jitter_min <- rtrunc_minutes(1, allow_max_min = allow_max_min)
    step_min <- as.numeric(target_min) + as.numeric(jitter_min)
    
    # Duration allows fractional minutes (avoids Period integer constraint)
    cur <- cur + lubridate::dminutes(step_min)
    
    if (cur >= end_dt) break
    times <- c(times, cur)
    step <- step + 1L
    if (step >= max_steps) break
  }
  # Ensure POSIXct(UTC) on return
  lubridate::as_datetime(times, tz = "UTC")
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
    start_dt = parse_dt(Date)  # returns POSIXct UTC
  )

# keep severities 2–5 and compute window + target
patients <- patients |>
  filter(Severity %in% 2:5) |>
  mutate(
    target_min = as.numeric(TARGET_MIN[as.character(Severity)]),
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

# Ensure Time_In is POSIXct UTC before using hour() to avoid tz() warnings
visits <- visits |>
  mutate(
    Time_In = lubridate::as_datetime(Time_In, tz = "UTC")
  )

# =========================
# Assign Employee_ID strictly within recorded shift windows
# =========================
visits <- visits |>
  mutate(
    .hour = lubridate::hour(lubridate::with_tz(Time_In, tzone = "UTC")),
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
    Time_In  = format(Time_In, "%Y-%m-%d %H:%M:%S"),
    Employee_ID
  )

# =========================
# 4) Save (CSV + ZIP)
# =========================
readr::write_csv(visits_out, OUTFILE)
zip(zipfile = ZIPFILE, files = OUTFILE, flags = "-j")

cat("✅ Wrote:", OUTFILE, " | rows:", nrow(visits_out), "\n")
cat("📦 Zipped:", ZIPFILE, "\n")
print(head(visits_out, 10))
