# install.packages(c("tidyverse","lubridate","stringr"), dependencies = TRUE)  # run once
library(tidyverse)
library(lubridate)
library(stringr)

set.seed(42)

# =========================
# Paths
# =========================
INFILE  <- "/cloud/project/Dataset_Locked_UCSF - Patient Intake.csv"
OUTFILE <- "/cloud/project/patient_visits.csv"
ZIPFILE <- "/cloud/project/patient_visits.zip"

# =========================
# Policy
# =========================
TARGET_MIN    <- c(`2`=30, `3`=60, `4`=90, `5`=120)  # minutes (Severity 1 excluded)
ALLOW_MAX_MIN <- 12                                   # + Uniform(0,12) minutes each step
EMPLOYEE_IDS  <- sprintf("NUR%03d", 1:60)            # simple roster

# =========================
# Helpers
# =========================
parse_dt <- function(x){
  suppressWarnings(lubridate::parse_date_time(
    x,
    orders = c("Y-m-d H:M:S","m/d/Y H:M:S","Y/m/d H:M:S","Y-m-d H:M","m/d/Y H:M","Y/m/d H:M"),
    quiet  = TRUE
  ))
}

# Per-patient cumulative schedule: t0 = start; tk = t(k-1) + target + U(0,12)
make_schedule_plus_u12 <- function(start_dt, end_dt, target_min, allow_max){
  tot <- as.numeric(difftime(end_dt, start_dt, units="mins"))
  if (is.na(tot) || tot <= 0) return(as.POSIXct(character(0), tz = tz(start_dt)))
  
  n_est <- ceiling(tot / target_min) + 2L
  allow <- as.difftime(runif(n_est, 0, allow_max), units="mins")
  step  <- as.difftime(rep(target_min, n_est), units="mins") + allow
  
  t <- vector("list", n_est)
  t[[1]] <- start_dt
  for (i in 2:n_est) t[[i]] <- t[[i-1]] + step[i-1]
  tt <- do.call(c, t)
  tt[tt >= start_dt & tt < end_dt]
}

`%||%` <- function(a,b) if (!is.null(a) && length(a) && !is.na(a)) a else b
pick <- function(aliases, pool) { intersect(aliases, pool)[1] %||% NA_character_ }

# =========================
# 1) Load & clean intake (auto-detect headers)
# =========================
stopifnot(file.exists(INFILE))
raw0 <- readr::read_csv(INFILE, show_col_types = FALSE)

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

# assign Employee_ID (kept)
visits <- visits |>
  mutate(Employee_ID = sample(EMPLOYEE_IDS, n(), replace = TRUE))

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
