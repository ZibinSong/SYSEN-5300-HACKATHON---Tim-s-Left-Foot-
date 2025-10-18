#install.packages(c("gert", "credentials"))
library(gert)

library(credentials)

credentials::set_github_pat()

# this will prompt a popup that asks you to enter your GitHub Personal Access Token.

gert::git_pull() # pull most recent changes from GitHub

gert::git_add(dir(all.files = TRUE)) # select any and all new files created or edited to be 'staged'

# 'staged' files are to be saved anew on GitHub 

gert::git_commit_all("my first commit") # save your record of file edits - called a commit

gert::git_push() # push your commit to GitHub
# install.packages(c("tidyverse","lubridate","stringr"), dependencies = TRUE)  # run once if needed
library(tidyverse)
library(lubridate)
library(stringr)

set.seed(42)

# ---------------------------------------------
# Paths
# ---------------------------------------------
INFILE  <- "/cloud/project/Dataset_Locked - Patient Intake.csv"
OUTFILE <- "/cloud/project/patient_visits.csv"
ZIPFILE <- "/cloud/project/patient_visits.zip"

# ---------------------------------------------
# Policy
# ---------------------------------------------
TARGET_MIN   <- c(`2`=30, `3`=60, `4`=90, `5`=120)  # minutes; Severity 1 excluded (immediate)
ALLOW_MAX    <- 12                                  # add + Uniform(0,12) minutes to each interval
VISIT_DUR_MIN <- c(min=10, max=25)                  # bedside visit duration (mins)
EMPLOYEE_IDS <- sprintf("NUR%03d", 1:60)            # simple fallback roster

# ---------------------------------------------
# Helpers
# ---------------------------------------------
# Robust parser for a single "Date" column (handles common formats from Sheets/Excel)
parse_dt <- function(x){
  suppressWarnings(lubridate::parse_date_time(
    x,
    orders = c("Y-m-d H:M:S","m/d/Y H:M:S","Y/m/d H:M:S","Y-m-d H:M","m/d/Y H:M","Y/m/d H:M"),
    quiet  = TRUE
  ))
}

# Build schedule cumulatively:
# t[1] = start_dt; t[k] = t[k-1] + target_min + Uniform(0, ALLOW_MAX)
make_schedule_plus_u12 <- function(start_dt, end_dt, target_min, allow_max){
  tot <- as.numeric(difftime(end_dt, start_dt, units="mins"))
  if (is.na(tot) || tot <= 0) return(as.POSIXct(character(0), tz = tz(start_dt)))
  
  n_est <- ceiling(tot / target_min) + 2L                # safe upper bound
  allow <- as.difftime(runif(n_est, 0, allow_max), units="mins")
  step  <- as.difftime(rep(target_min, n_est), units="mins") + allow
  
  t <- vector("list", n_est)
  t[[1]] <- start_dt
  for (i in 2:n_est) t[[i]] <- t[[i-1]] + step[i-1]
  tt <- do.call(c, t)
  
  tt[tt >= start_dt & tt < end_dt]                      # keep within stay window
}

# ---------------------------------------------
# 1) Load & clean intake
# ---------------------------------------------
stopifnot(file.exists(INFILE))
raw <- read_csv(INFILE, show_col_types = FALSE)

# normalize headers + fix known typos from your file
names(raw) <- names(raw) |> str_trim() |> str_replace_all("\\s+","_")
names(raw)[names(raw) == "Patient__ID"] <- "Patient_ID"   # "Patient_ ID" -> "Patient__ID"
names(raw)[names(raw) == "Serverity"]   <- "Severity"
names(raw)[names(raw) == "Frenquency"]  <- "Frequency"
raw <- raw |> select(!starts_with("Unnamed"))

patients <- raw |>
  mutate(
    Severity = suppressWarnings(as.integer(Severity)),
    Days     = suppressWarnings(as.integer(ifelse(is.na(Days), 3L, Days))),
    start_dt = parse_dt(Date)
  )

req <- c("Patient_ID","Room_Number","Severity","start_dt","Days")
stopifnot(all(req %in% names(patients)))
if (any(is.na(patients$start_dt))) stop("Some Date values could not be parsed. Check the 'Date' column format.")

# Only severities 2..5 are scheduled
patients <- patients |>
  filter(Severity %in% 2:5) |>
  mutate(
    target_min = TARGET_MIN[as.character(Severity)],
    stay_end   = start_dt + days(Days)
  )

# ---------------------------------------------
# 2) Expand into visit rows with correct spacing
# ---------------------------------------------
visits <- patients |>
  rowwise() |>
  mutate(Time_in_list = list(make_schedule_plus_u12(start_dt, stay_end, target_min, ALLOW_MAX))) |>
  ungroup() |>
  select(Patient_ID, Room_Number, Severity, target_min, Time_in_list) |>
  unnest(Time_in_list, names_repair = "minimal") |>
  rename(Time_in = Time_in_list) |>
  arrange(Patient_ID, Time_in)

# QA (optional): realized gap between consecutive visits for the same patient
visits <- visits |>
  group_by(Patient_ID) |>
  arrange(Time_in, .by_group = TRUE) |>
  mutate(gap_min = c(NA_real_, as.numeric(diff(Time_in), units = "mins"))) |>
  ungroup()

# Add Time_out and assign employee id
visits <- visits |>
  mutate(
    Time_out    = Time_in + as.difftime(runif(n(), VISIT_DUR_MIN["min"], VISIT_DUR_MIN["max"]), units = "mins"),
    employee_id = sample(EMPLOYEE_IDS, n(), replace = TRUE)
  )

# Final output table (keep severity & target for alignment)
visits_out <- visits |>
  group_by(Patient_ID) |>
  mutate(`# of visit` = row_number()) |>
  ungroup() |>
  transmute(
    `# of visit`,
    `Room number`     = Room_Number,
    `Patient Number`  = Patient_ID,
    Severity          = Severity,
    Target_min        = target_min,
    Allowance_added   = "U(0,12) min",
    `Time in`         = format(Time_in,  "%Y-%m-%d %H:%M:%S"),
    `time out`        = format(Time_out, "%Y-%m-%d %H:%M:%S"),
    `employee id`     = employee_id
  )

# ---------------------------------------------
# 3) Save (CSV + ZIP for download)
# ---------------------------------------------
readr::write_csv(visits_out, OUTFILE)
zip(zipfile = ZIPFILE, files = OUTFILE, flags = "-j")   # -j: no folder paths inside zip
cat("✅ Wrote:", OUTFILE, " | rows:", nrow(visits_out), "\n")
cat("📦 Zipped:", ZIPFILE, "\n")

# peek
print(head(visits_out, 10))

