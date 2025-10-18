# Six Sigma Process Control Dashboard
# A comprehensive Shiny application for monitoring and analyzing process performance

# Load required libraries
library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)

# Define UI
ui <- dashboardPage(
  # Dark theme styling
  skin = "black",
  
  # Header
  dashboardHeader(
    title = "SigmaView",
    titleWidth = 200,
    tags$li(
      class = "dropdown",
      tags$a(href = "#", "Dashboard", class = "nav-link")
    ),
    tags$li(
      class = "dropdown",
      tags$a(href = "#", "Reports", class = "nav-link")
    ),
    tags$li(
      class = "dropdown",
      tags$a(href = "#", "Settings", class = "nav-link")
    ),
    tags$li(
      class = "dropdown",
      tags$div(
        style = "width: 40px; height: 40px; border-radius: 50%; background-color: #ff69b4; margin: 5px; display: flex; align-items: center; justify-content: center;",
        tags$span(style = "color: white; font-size: 18px;", "👤")
      )
    )
  ),
  
  # Sidebar with Two-Tier Filtering System
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      # Primary Filter
      menuItem(
        "Filter Data",
        tabName = "filters",
        icon = icon("filter"),
        startExpanded = TRUE,
        selectInput(
          "primary_filter",
          "Analyze By",
          choices = c(
            "Time of Day" = "time_of_day",
            "Wing" = "wing", 
            "Severity" = "severity",
            "Caregiver Gender" = "caregiver_gender"
          ),
          selected = "time_of_day"
        ),
        
        # Secondary Filter (Dynamically Rendered)
        uiOutput("secondary_filter")
      )
    )
  ),
  
  # Main Body
  dashboardBody(
    # Custom CSS for dark theme and styling
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #2c3e50 !important;
        }
        .main-header .navbar {
          background-color: #34495e !important;
        }
        .main-header .navbar .nav > li > a {
          color: white !important;
        }
        .main-header .logo {
          background-color: #34495e !important;
          color: white !important;
        }
        .sidebar-menu > li.active > a {
          background-color: #3498db !important;
        }
        .box {
          background-color: #34495e !important;
          border: 1px solid #4a5f7a !important;
        }
        .box-header {
          background-color: #2c3e50 !important;
          border-bottom: 1px solid #4a5f7a !important;
        }
        .box-title {
          color: white !important;
        }
        .small-box {
          background-color: #34495e !important;
          border: 1px solid #4a5f7a !important;
        }
        .small-box .icon {
          color: #3498db !important;
        }
        .small-box h3 {
          color: white !important;
        }
        .small-box p {
          color: #bdc3c7 !important;
        }
        .info-box {
          background-color: #34495e !important;
          border: 1px solid #4a5f7a !important;
        }
        .info-box-content {
          color: white !important;
        }
        .info-box-text {
          color: #bdc3c7 !important;
        }
        .info-box-number {
          color: white !important;
        }
        .nav-tabs-custom {
          background-color: #34495e !important;
          border: 1px solid #4a5f7a !important;
        }
        .nav-tabs-custom > .nav-tabs > li.active > a {
          background-color: #2c3e50 !important;
          color: white !important;
        }
        .nav-tabs-custom > .nav-tabs > li > a {
          color: #bdc3c7 !important;
        }
        .nav-tabs-custom > .tab-content {
          background-color: #2c3e50 !important;
        }
        .dataTables_wrapper {
          background-color: #34495e !important;
        }
        .dataTables_wrapper .dataTables_length,
        .dataTables_wrapper .dataTables_filter,
        .dataTables_wrapper .dataTables_info,
        .dataTables_wrapper .dataTables_paginate {
          color: white !important;
        }
        .dataTables_wrapper .dataTables_length select,
        .dataTables_wrapper .dataTables_filter input {
          background-color: #2c3e50 !important;
          color: white !important;
          border: 1px solid #4a5f7a !important;
        }
        .dataTables_wrapper table.dataTable {
          background-color: #34495e !important;
          color: white !important;
        }
        .dataTables_wrapper table.dataTable thead th {
          background-color: #2c3e50 !important;
          color: white !important;
          border-bottom: 1px solid #4a5f7a !important;
        }
        .dataTables_wrapper table.dataTable tbody td {
          border-bottom: 1px solid #4a5f7a !important;
        }
        .dataTables_wrapper table.dataTable tbody tr:hover {
          background-color: #4a5f7a !important;
        }
      "))
    ),
    
    # Main Dashboard Title
    fluidRow(
      column(12, 
        h1("Six Sigma Process Control", 
           style = "color: white; text-align: center; margin: 20px 0; font-weight: bold;")
      )
    ),
    
    # KPI & Metrics Section - Seven Metric Cards
    fluidRow(
      # Main KPIs (3 cards)
      valueBox(
        value = "1.25",
        subtitle = "Overall Interval Cpk",
        icon = icon("chart-line"),
        color = "blue",
        width = 4
      ),
      valueBox(
        value = "3.5%",
        subtitle = "Non-Compliance Rate", 
        icon = icon("exclamation-triangle"),
        color = "yellow",
        width = 4
      ),
      valueBox(
        value = "7",
        subtitle = "Live OOC Alerts",
        icon = icon("bell"),
        color = "red",
        width = 4
      )
    ),
    
    # Statistical Metrics (4 cards)
    fluidRow(
      valueBox(
        value = "2.3 min",
        subtitle = "Mean Deviation (Lateness)",
        icon = icon("clock"),
        color = "green",
        width = 3
      ),
      valueBox(
        value = "1.8",
        subtitle = "Standard Deviation (SD)",
        icon = icon("calculator"),
        color = "purple",
        width = 3
      ),
      valueBox(
        value = "1.9 min",
        subtitle = "Median Deviation",
        icon = icon("chart-bar"),
        color = "teal",
        width = 3
      ),
      valueBox(
        value = "15.2 min",
        subtitle = "Avg T_Actual",
        icon = icon("stopwatch"),
        color = "orange",
        width = 3
      )
    ),
    
    # Main Visualization Area (7:5 fluid layout)
    fluidRow(
      # Left Column (7-width) - X-bar Control Chart
      column(
        width = 7,
        box(
          title = "Interval Deviation Control Chart",
          subtitle = "Last 30 Days",
          status = "primary",
          solidHeader = TRUE,
          width = NULL,
          height = 500,
          tags$div(
            style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;",
            tags$span(style = "color: #bdc3c7; font-size: 14px;", "Last 30 Days"),
            tags$span(style = "color: #e74c3c; font-weight: bold;", "↘ -1.5%")
          ),
          plotlyOutput("control_chart", height = "400px")
        )
      ),
      
      # Right Column (5-width) - Root Cause Pareto Chart and Exception Log
      column(
        width = 5,
        # Root Cause Pareto Chart
        box(
          title = "Top 5 Root Causes",
          subtitle = "Last 30 Days",
          status = "primary",
          solidHeader = TRUE,
          width = NULL,
          height = 250,
          tags$div(
            style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;",
            tags$span(style = "color: #bdc3c7; font-size: 14px;", "Last 30 Days"),
            tags$span(style = "color: #27ae60; font-weight: bold;", "↗ +2.1%")
          ),
          plotlyOutput("pareto_chart", height = "150px")
        ),
        
        # Exception Log Data Table
        box(
          title = "Exception Log Data Table",
          status = "primary",
          solidHeader = TRUE,
          width = NULL,
          height = 250,
          DTOutput("exception_table")
        )
      )
    )
  )
)

# Define Server Logic
server <- function(input, output, session) {
  
  # Dynamic Secondary Filter Logic
  output$secondary_filter <- renderUI({
    primary_choice <- input$primary_filter
    
    # Define secondary filter options based on primary selection
    secondary_options <- switch(primary_choice,
      "time_of_day" = c("Morning Shift" = "morning", 
                        "Afternoon Shift" = "afternoon",
                        "Evening Shift" = "evening",
                        "Night Shift" = "night"),
      "wing" = c("SW" = "sw", 
                 "MW" = "mw", 
                 "MATW" = "matw", 
                 "RW" = "rw"),
      "severity" = c("Low" = "low", 
                     "Medium" = "medium", 
                     "High" = "high", 
                     "Critical" = "critical"),
      "caregiver_gender" = c("Male" = "male", 
                             "Female" = "female", 
                             "Other" = "other")
    )
    
    selectInput(
      "secondary_filter",
      "Select Specific Group",
      choices = secondary_options,
      selected = secondary_options[1]
    )
  })
  
  # Generate sample data for visualizations
  sample_data <- reactive({
    set.seed(123)
    data.frame(
      time = seq(as.Date("2024-01-01"), as.Date("2024-01-30"), by = "day"),
      deviation = rnorm(30, mean = 2.3, sd = 1.8),
      ucl = rep(5.0, 30),
      lcl = rep(-0.5, 30),
      target = rep(0, 30)
    )
  })
  
  # X-bar Control Chart
  output$control_chart <- renderPlotly({
    data <- sample_data()
    
    p <- plot_ly(data, x = ~time, y = ~deviation, type = 'scatter', mode = 'lines+markers',
                 name = 'Deviation', line = list(color = '#3498db', width = 2),
                 marker = list(color = '#3498db', size = 6)) %>%
      add_trace(y = ~ucl, name = 'UCL', line = list(color = '#e74c3c', dash = 'dash', width = 2)) %>%
      add_trace(y = ~lcl, name = 'LCL', line = list(color = '#e74c3c', dash = 'dash', width = 2)) %>%
      add_trace(y = ~target, name = 'Target', line = list(color = '#27ae60', dash = 'dot', width = 2)) %>%
      layout(
        title = "",
        xaxis = list(title = "Date", color = 'white', gridcolor = '#4a5f7a'),
        yaxis = list(title = "Deviation (minutes)", color = 'white', gridcolor = '#4a5f7a'),
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)',
        font = list(color = 'white'),
        legend = list(font = list(color = 'white'))
      )
    
    # Highlight out-of-control points
    ooc_points <- which(data$deviation > data$ucl | data$deviation < data$lcl)
    if(length(ooc_points) > 0) {
      p <- p %>% add_trace(
        x = data$time[ooc_points], 
        y = data$deviation[ooc_points],
        type = 'scatter', mode = 'markers',
        name = 'OOC', 
        marker = list(color = '#e74c3c', size = 10),
        showlegend = FALSE
      )
    }
    
    p
  })
  
  # Root Cause Pareto Chart
  output$pareto_chart <- renderPlotly({
    root_causes <- data.frame(
      cause = c("Staffing Shortages", "Equipment Malfunctions", "Communication Errors", 
                "Patient Non-Compliance", "Medication Delays"),
      percentage = c(90, 70, 55, 40, 25)
    )
    
    plot_ly(root_causes, x = ~cause, y = ~percentage, type = 'bar',
            marker = list(color = '#3498db')) %>%
      layout(
        title = "",
        xaxis = list(title = "", color = 'white', tickangle = -45),
        yaxis = list(title = "Percentage (%)", color = 'white'),
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)',
        font = list(color = 'white'),
        showlegend = FALSE
      )
  })
  
  # Exception Log Data Table
  output$exception_table <- renderDT({
    set.seed(456)
    exception_data <- data.frame(
      Timestamp = seq(as.POSIXct("2024-01-01 08:00:00"), 
                     as.POSIXct("2024-01-01 17:00:00"), 
                     by = "2 hours"),
      Severity = sample(c("High", "Medium", "Low"), 5, replace = TRUE),
      Description = c("Equipment malfunction in Wing A", 
                     "Staff shortage - 2 nurses absent",
                     "Patient non-compliance with medication",
                     "Communication error between shifts",
                     "Medication delivery delay"),
      Status = sample(c("Open", "In Progress", "Resolved"), 5, replace = TRUE),
      Assigned_To = sample(c("John Smith", "Sarah Johnson", "Mike Davis"), 5, replace = TRUE)
    )
    
    datatable(
      exception_data,
      options = list(
        pageLength = 5,
        dom = 't',
        scrollY = '150px',
        scrollCollapse = TRUE
      ),
      rownames = FALSE,
      class = 'compact'
    ) %>%
      formatStyle(
        columns = names(exception_data),
        backgroundColor = '#34495e',
        color = 'white'
      ) %>%
      formatStyle(
        "Severity",
        backgroundColor = styleEqual(c("High", "Medium", "Low"), c("#e74c3c", "#f39c12", "#27ae60"))
      )
  })
}

# Run the application
shinyApp(ui = ui, server = server)



