# SigmaView — Dashboard + Safe Loader (no more coalesce() name errors)
# -------------------------------------------------------------------
suppressPackageStartupMessages({
  library(shiny); library(shinydashboard); library(plotly); library(DT)
  library(dplyr); library(tidyr); library(stringr); library(lubridate); library(readr)
})

# ------------ Files ------------
PATH_MED   <- "/cloud/project/MedSize_visits.csv"
PATH_UCSF  <- "/cloud/project/patient_visits 7.csv"
PATH_GOOD  <- "Good_Sam_visits_Mid_Hospital (2).csv"

file_if_exists <- function(p) if (file.exists(p)) p else NA_character_

# ------------ Your lateness functions (unchanged in behavior) ------------
adjustTime <- function(data) {
  data %>%
    mutate(
      modify1 = gsub("/", "-", as.character(.data$Time_In)),
      timeIN_posix = suppressWarnings(as.POSIXct(modify1, format = "%Y-%m-%d %H:%M:%S", tz="UTC"))
    ) %>%
    mutate(
      timeIN_posix = ifelse(is.na(timeIN_posix),
                            suppressWarnings(parse_date_time(modify1,
                                                             orders=c("ymd HMS","ymd HM","ymd H","mdy HMS","mdy HM","mdy H",
                                                                      "dmy HMS","dmy HM","dmy H","HMS","HM","H"),
                                                             tz="UTC", quiet=TRUE)),
                            timeIN_posix)) %>%
    mutate(timeIN_posix = as.POSIXct(timeIN_posix, origin="1970-01-01", tz="UTC"))
}

interval_accuracy <- function(data){
  data %>%
    group_by(.data$Patient_ID) %>% 
    arrange(.data$Patient_ID, .data$timeIN_posix) %>%
    mutate(
      prev_timeIN = lag(timeIN_posix),
      difference  = as.numeric(difftime(timeIN_posix, prev_timeIN, units = "mins")),
      interval_deviation = difference - as.numeric(.data$Target_min),
      normalized_intervalDiff = interval_deviation / as.numeric(.data$Target_min),
      normalized_intervalDiff = ifelse(normalized_intervalDiff < 0, 0, normalized_intervalDiff)
    ) %>% ungroup()
}

late_min <- function(data){
  data %>% group_by(.data$Patient_ID, .data$timeIN_posix) %>% 
    mutate(
      exp_time = prev_timeIN + as.numeric(.data$Target_min)*60,
      late_by  = as.numeric(difftime(timeIN_posix, exp_time, units = "mins")),
      late_by  = ifelse (late_by < 0, 0, late_by)
    ) %>% ungroup()
}

final_format <- function(data){
  data$timeIN_hr <- as.integer(format(data$timeIN_posix, "%H"))
  data
}

Generate <- function(data){
  data %>% adjustTime() %>% interval_accuracy() %>% late_min() %>% final_format()
}

# ------------ Safe name mapping helpers ------------
# Map whichever candidate column exists into a **standard** column name.
apply_name_map <- function(df, map){
  for (std in names(map)) {
    found <- intersect(map[[std]], names(df))
    if (length(found)) {
      df[[std]] <- df[[found[1]]]
    } else {
      # ensure the standard column exists (filled with NA if missing)
      df[[std]] <- NA
    }
  }
  df
}

# ------------ Robust per-file loader ------------
load_visits_one <- function(path, label){
  if (is.na(path) || !file.exists(path)) return(tibble())
  
  raw <- suppressWarnings(read_csv(path, show_col_types = FALSE))
  
  # Try to discover the time and target columns by common aliases and rename into Time_In / Target_min
  raw <- apply_name_map(raw, list(
    Time_In    = c("Time_In","time_in","TimeIN","TIME_IN","Time In","time in","timestamp","datetime","date_time","checkin_time"),
    Target_min = c("Target_min","target_min","Target","target","expected_interval_min","expected_minutes","frequency_min"),
    Patient_ID = c("Patient_ID","patient_id","ID","id"),
    Employee_ID= c("Employee_ID","employee_id","caregiver_id","nurse_id","staff_id"),
    Wing       = c("Wing","wing","unit","department","ward","service_line"),
    Severity   = c("Severity","severity","severity_score","esi","acuity")
  ))
  
  # If still no Patient_ID, create a stable surrogate
  if (!"Patient_ID" %in% names(raw) || all(is.na(raw$Patient_ID))) {
    raw$Patient_ID <- seq_len(nrow(raw))
  }
  
  # Coerce important types
  raw$Severity   <- suppressWarnings(as.integer(raw$Severity))
  raw$Target_min <- suppressWarnings(as.numeric(raw$Target_min))
  
  # Run your pipeline (requires Time_In + Target_min present; we created them above if needed)
  out <- Generate(raw) %>%
    mutate(
      source = label,
      shift = case_when(
        timeIN_hr >= 6  & timeIN_hr < 14 ~ "morning",
        timeIN_hr >= 14 & timeIN_hr < 22 ~ "day",
        TRUE ~ "night"
      ),
      date = as.Date(timeIN_posix),
      deviation_raw = interval_deviation
    ) %>%
    transmute(
      source,
      Patient_ID,
      Employee_ID,
      Wing = ifelse(is.na(Wing) | Wing=="", NA_character_, as.character(Wing)),
      Severity = as.integer(Severity),
      date,
      timeIN = timeIN_posix,
      timeIN_hr,
      Target_min = as.numeric(Target_min),
      interval_deviation = as.numeric(interval_deviation),
      normalized_intervalDiff = as.numeric(normalized_intervalDiff),
      late_by = as.numeric(late_by),
      deviation_raw,
      shift
    )
  
  out %>% filter(!is.na(date))
}

# ------------ Load all available systems ------------
DATA <- bind_rows(
  load_visits_one(file_if_exists(PATH_MED),  "MedSize"),
  load_visits_one(file_if_exists(PATH_UCSF), "UCSF"),
  load_visits_one(file_if_exists(PATH_GOOD), "Good Sam")
)

# ------------ UI ------------
ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "Six Sigma Process Control Dashboard", titleWidth = 340),
  dashboardSidebar(
    width = 320,
    tags$head(tags$style(HTML("
      body, .content-wrapper { background:#0f1720 !important; }
      .sidebar { background:#0b121a !important; }
      .box { background:#111a24 !important; border:1px solid #1f2a37; border-radius:14px; }
      .box-header { background:#0f1720 !important; border-bottom:1px solid #1f2a37; }
      .box-title, .sidebar a, .control-label, .info-box-text, .info-box-number { color:#e5eef7 !important; }
      .skin-black .main-header .navbar { background:#0b121a; border-bottom:1px solid #1f2a37; }
      .skin-black .main-header .logo { background:#0b121a; color:#e5eef7; }
      .form-control, .selectize-input, .input-group-addon { background:#0f1720 !important; color:#e5eef7 !important; border:1px solid #1f2a37 !important; }
      .value-card { background:#111a24; border:1px solid #1f2a37; border-radius:16px; padding:18px 20px; }
      .value-title { color:#9fb1c1; font-size:13px; margin-bottom:6px; }
      .value-main { color:#e5eef7; font-size:28px; font-weight:700; }
      .value-delta-up { color:#4ade80; font-size:12px; }
      .value-delta-down { color:#f87171; font-size:12px; }
      .kpi-row .col-sm-4, .kpi-row .col-sm-3 { padding:10px; }
      #exception_table table.dataTable tbody td, 
      #exception_table table.dataTable thead th { color:#f0f6ff !important; }
    "))),
    h4("Filters", style="color:#e5eef7; padding: 10px 15px 0;"),
    div(style="padding: 10px 15px;",
        selectInput("file_choice", "Hospital System",
                    choices = {
                      opts <- c()
                      if (nrow(filter(DATA, source=="MedSize")))  opts <- c(opts, "Med Patient Intake"="MedSize")
                      if (nrow(filter(DATA, source=="UCSF")))     opts <- c(opts, "UCSF Patient Intake"="UCSF")
                      if (nrow(filter(DATA, source=="Good Sam"))) opts <- c(opts, "Good Sam"="Good Sam")
                      if (length(opts) > 1) c("All Systems"="ALL", opts) else opts
                    },
                    selected = ifelse("ALL" %in% names(
                      {opts <- c()
                      if (nrow(filter(DATA, source=="MedSize")))  opts <- c(opts, MedSize="MedSize")
                      if (nrow(filter(DATA, source=="UCSF")))     opts <- c(opts, UCSF="UCSF")
                      if (nrow(filter(DATA, source=="Good Sam"))) opts <- c(opts, GoodSam="Good Sam"); opts}), "ALL",
                      ifelse(nrow(filter(DATA, source=="Good Sam")),"Good Sam",
                             ifelse(nrow(filter(DATA, source=="MedSize")),"MedSize","UCSF")))),
        selectInput("primary_filter", "Analyze By",
                    choices = c("Shift"="shift","Severity (1-5)"="severity","Wing"="wing"),
                    selected = "shift"),
        uiOutput("secondary_filter_ui"),
        dateRangeInput("daterange", "Date range",
                       start = if (nrow(DATA)) max(Sys.Date()-29, min(DATA$date, na.rm=TRUE)) else Sys.Date()-29,
                       end   = if (nrow(DATA)) max(DATA$date, na.rm=TRUE) else Sys.Date()),
        selectInput("metric_col", "Metric for chart/table",
                    choices = c("Interval deviation (min)"="interval_deviation",
                                "Late-by (min)"="late_by",
                                "Normalized interval diff"="normalized_intervalDiff"),
                    selected="interval_deviation"),
        helpText("Tip: choose 'All' if a specific group hides everything.", style="color:#9fb1c1;")
    )
  ),
  dashboardBody(
    fluidRow(
      column(12, h2("Key Performance Indicators",
                    style="color:#e5eef7; margin: 10px 0 14px 4px;"))
    ),
    fluidRow(class="kpi-row",
             column(4, div(class="value-card",
                           div(class="value-title","Process Cpk"),
                           div(class="value-main", textOutput("kpi_cpk")),
                           div(class="value-delta-up", HTML("&uarr; +0.1%")))),
             column(4, div(class="value-card",
                           div(class="value-title","Lateness Rate (%)"),
                           div(class="value-main", textOutput("kpi_late_rate")),
                           div(class="value-delta-down", HTML("&darr; -0.2%")))),
             column(4, div(class="value-card",
                           div(class="value-title","OOC Alerts (Live)"),
                           div(class="value-main", textOutput("kpi_ooc")),
                           div(class="value-delta-up", HTML("&uarr; +1"))))
    ),
    fluidRow(class="kpi-row",
             column(4, div(class="value-card",
                           div(class="value-title","Mean Deviation"),
                           div(class="value-main", textOutput("kpi_mean")))),
             column(4, div(class="value-card",
                           div(class="value-title","Standard Deviation (SD)"),
                           div(class="value-main", textOutput("kpi_sd")))),
             column(4, div(class="value-card",
                           div(class="value-title","Avg Actual Time"),
                           div(class="value-main", textOutput("kpi_avg_actual"))))
    ),
    fluidRow(
      box(title="X-bar Control Chart: Interval Deviation",
          width = 8, solidHeader = TRUE, status = "primary",
          div(style="color:#9fb1c1; margin:-8px 0 6px 2px;", "Daily mean of selected metric"),
          plotlyOutput("control_chart", height = 420)),
      box(title="Exception Log",
          width = 4, solidHeader = TRUE, status = "primary",
          DTOutput("exception_table", width = "100%"))
    ),
    fluidRow(
      box(title="Filtered Data Preview", width=12, solidHeader=TRUE, status="primary",
          DTOutput("visits_table"))
    )
  )
)

# ------------ Server ------------
server <- function(input, output, session){
  
  base_visits <- reactive({
    if (!nrow(DATA)) return(DATA)
    if (isTruthy(input$file_choice) && input$file_choice != "ALL") {
      DATA %>% filter(source == input$file_choice)
    } else DATA
  })
  
  # Secondary options — unique FIRST, then names (fixes names-length error)
  output$secondary_filter_ui <- renderUI({
    pf <- req(input$primary_filter)
    df <- base_visits()
    
    if (pf == "shift") {
      choices <- c("All"="__ALL__", "Morning"="morning", "Day"="day", "Night"="night")
    } else if (pf == "severity") {
      vals <- sort(unique(df$Severity[df$Severity %in% 1:5]))
      choices <- if (length(vals)) c("All"="__ALL__", stats::setNames(as.character(vals), paste0("Severity ", vals)))
      else c("All"="__ALL__")
    } else { # wing
      vals <- sort(unique(na.omit(as.character(df$Wing))))
      lab  <- if (length(vals)) ifelse(grepl("^[A-Z0-9_-]+$", vals), vals, tools::toTitleCase(vals)) else character(0)
      choices <- if (length(vals)) c("All"="__ALL__", stats::setNames(vals, lab)) else c("All"="__ALL__")
    }
    
    selectInput("secondary_value", "Select Specific Group", choices = choices, selected = "__ALL__")
  })
  
  observeEvent(input$file_choice, {
    df <- base_visits()
    if (nrow(df)) {
      updateDateRangeInput(session, "daterange",
                           start = max(Sys.Date()-29, min(df$date, na.rm=TRUE)),
                           end   = max(df$date, na.rm=TRUE))
    }
  }, ignoreInit = TRUE)
  
  filtered_visits <- reactive({
    req(input$daterange)
    df <- base_visits() %>% filter(date >= as.Date(input$daterange[1]),
                                   date <= as.Date(input$daterange[2]))
    sv <- input$secondary_value
    if (!is.null(sv) && sv != "__ALL__") {
      if (input$primary_filter == "severity")      df <- df %>% filter(Severity == as.integer(sv))
      else if (input$primary_filter == "shift")    df <- df %>% filter(shift == sv)
      else                                          df <- df %>% filter(Wing == sv)
    }
    df
  })
  
  # KPIs
  cpk_calc <- function(mu, sigma_s, usl=5, lsl=-5){
    if(is.na(sigma_s) || sigma_s == 0) return(NA_real_)
    min((usl - mu)/(3*sigma_s), (mu - lsl)/(3*sigma_s))
  }
  active_metric <- reactive({
    m <- req(input$metric_col)
    if (!m %in% names(DATA)) "interval_deviation" else m
  })
  kpi_data <- reactive({
    dat <- filtered_visits(); m <- active_metric()
    v <- dat[[m]]
    mu <- mean(v, na.rm=TRUE); sdv <- sd(v, na.rm=TRUE)
    late_rate <- mean(dat$late_by > 0, na.rm=TRUE) * 100
    avg_actual <- mean(dat$Target_min + pmax(0, dat$interval_deviation), na.rm=TRUE)
    ooc_n <- if (all(is.na(v))) 0 else { mm <- mean(v, na.rm=TRUE); ss <- sd(v, na.rm=TRUE); sum(v > mm + 3*ss | v < mm - 3*ss, na.rm=TRUE) }
    list(mu=mu, sd=sdv, cpk=cpk_calc(mu, sdv), late_rate=late_rate, avg_actual=avg_actual, ooc=ooc_n)
  })
  output$kpi_cpk        <- renderText(sprintf("%.2f", kpi_data()$cpk))
  output$kpi_late_rate  <- renderText(sprintf("%.1f%%", kpi_data()$late_rate))
  output$kpi_ooc        <- renderText(kpi_data()$ooc)
  output$kpi_mean       <- renderText(sprintf("%.2f", kpi_data()$mu))
  output$kpi_sd         <- renderText(sprintf("%.2f", kpi_data()$sd))
  output$kpi_avg_actual <- renderText(sprintf("%.1f mins", kpi_data()$avg_actual))
  
  output$control_chart <- renderPlotly({
    dat <- filtered_visits() %>% arrange(date, timeIN)
    m <- active_metric()
    validate(
      need(nrow(dat) > 0, "No rows match the current filters."),
      need(sum(!is.na(dat[[m]])) > 1, "Selected metric is all NA here.")
    )
    daily <- dat %>% mutate(day = as.Date(timeIN)) %>%
      group_by(day) %>% summarise(val = mean(.data[[m]], na.rm=TRUE), .groups="drop")
    mu  <- mean(daily$val, na.rm=TRUE); sdv <- sd(daily$val, na.rm=TRUE)
    ucl <- mu + 3*sdv; lcl <- mu - 3*sdv
    idx <- which(daily$val > ucl | daily$val < lcl)
    
    p <- plot_ly(daily, x=~day, y=~val, type='scatter', mode='lines+markers',
                 name='Daily mean', line=list(width=2)) %>%
      add_trace(y=~I(rep(ucl,nrow(daily))), name='UCL', mode='lines', line=list(dash='dash', width=1.5)) %>%
      add_trace(y=~I(rep(lcl,nrow(daily))), name='LCL', mode='lines', line=list(dash='dash', width=1.5)) %>%
      add_trace(y=~I(rep(mu, nrow(daily))), name='Mean', mode='lines', line=list(dash='dot', width=1.2))
    if(length(idx)>0) p <- p %>% add_markers(x=daily$day[idx], y=daily$val[idx], name='OOC', marker=list(size=10))
    p %>% layout(
      xaxis=list(title=NULL, color='#e5eef7', gridcolor='#1f2a37'),
      yaxis=list(title="Selected metric", color='#e5eef7', gridcolor='#1f2a37'),
      legend=list(font=list(color='#e5eef7')),
      plot_bgcolor='rgba(0,0,0,0)', paper_bgcolor='rgba(0,0,0,0)', font=list(color='#e5eef7')
    )
  })
  
  output$exception_table <- renderDT({
    df <- filtered_visits(); m <- active_metric()
    if (!nrow(df) || !m %in% names(df) || all(is.na(df[[m]]))) {
      return(datatable(tibble(Note="No exceptions in this slice."),
                       options=list(dom='t'), rownames=FALSE))
    }
    x <- df[[m]]; mu <- mean(x, na.rm=TRUE); sdv <- sd(x, na.rm=TRUE)
    oo <- which(x > mu + 3*sdv | x < mu - 3*sdv)
    ex <- if (!length(oo)) tibble(Note="No exceptions in this slice.") else tibble(
      `EVENT ID`   = df$Patient_ID[oo],
      `TIMESTAMP`  = format(df$timeIN[oo], "%H:%M"),
      `TYPE`       = "Check-in",
      `DETAIL`     = paste0("OOC ", m, " = ", round(x[oo],2))
    )
    datatable(ex, options=list(pageLength=8, dom='tip', ordering=FALSE),
              rownames=FALSE, class='compact stripe hover')
  })
  
  output$visits_table <- renderDT({
    datatable(filtered_visits(), options=list(pageLength=10, dom='tip'), rownames=FALSE)
  })
}

shinyApp(ui, server)
