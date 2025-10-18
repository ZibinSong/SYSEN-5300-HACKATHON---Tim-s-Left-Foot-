# INSTALL PACKAGES

#install.packages("tidyverse")
#install.packages("truncnorm")
#install.packages("ggplot2")
library(dplyr)
library(truncnorm)
library(ggplot2)

##############################################################################
# USER INPUT:
##############################################################################

  # Add Patient Visits File here:
  visits = read.csv("Good_Sam_visits_Mid_Hospital (2).csv")
  
  # Generate Table of QuantInterests:
  QuantInterests = Generate(visits)
  
  # Run Diagnostics on Lateness:
  Diagnostics(QuantInterests)
  
##############################################################################
# QUALITIES OF INTEREST CALCULATION:
##############################################################################
  
  # Generate Function #######################################
  # Fully formats and adds qualities of interest to inputted dataset
  Generate <- function(data){
    data = adjustTime(data)
    data = interval_accuracy(data)
    data = late_min(data)
    data = final_format(data)
    return(data)
  }
  
  # Function 1 ##############################################
  # Adjusting data so we can subtract timestamps
  # data must have columns: Time_In, Target_min, Days
  adjustTime <- function(data) {
    data %>%
      mutate(
        
        # need to format correctly to use the timestamps
        modify1 = gsub("/", "-", Time_In),
        # modify2 = gsub("/", "-", Time_Out),
        
        timeIN  = as.POSIXct(modify1, format = "%Y-%m-%d %H:%M:%S"),
        # timeOUT = as.POSIXct(modify2, format = "%m-%d-%Y %H:%M:%S"),
        
        # number of visits expected, in total
        # num_visits = Frequency*Days,
        
        # Target_min = 1440 / (Num_Visits / Days)
        
        # frequency is number of visits per day
        # so now convert frequency interval into minutes
        # Target_min = 1440 / Frequency
      )
  }
  
  # Function 2 ####################################################
  # Calculate and record the time between checkups for patients
  # data must have the columns: Patient_ID, timeIN, Target_min
  
  interval_accuracy = function(data){
    data %>% group_by(Patient_ID) %>% 
      arrange(Patient_ID, timeIN) %>%  # Ensure chronological order
      mutate(
        
        # previous check in times
        prev_timeIN = lag(timeIN),
        
        # how many minutes off you are from the expected frequency interval
        difference = as.numeric(difftime(timeIN, prev_timeIN, units = "mins")),
        
        # difference from expected interval  
        interval_deviation = difference - Target_min,
        
        # normalize the value because of different frequency times
        normalized_intervalDiff = interval_deviation / Target_min, 
        
        # if caregiver is early, then they're not late. The interval difference is 0
        normalized_intervalDiff = ifelse (normalized_intervalDiff < 0, 0, normalized_intervalDiff)
      ) %>%
      ungroup()
  }
  
  # Function 3 ######################################################
  # Caclulate and record how late caregivers are to check in on their patients
  late_min = function(data){
    data %>% group_by(Patient_ID, timeIN) %>% 
      mutate(
        # expected time for next check in 
        exp_time = prev_timeIN + Target_min*60,
        
        # difference from expected time of check in
        late_by = as.numeric(difftime(timeIN, exp_time, units = "mins")),
        
        # if caregiver is early, then they're not late. Late by "0" minutes
        late_by = ifelse (late_by < 0, 0, late_by)
      )
  }
  
  # Function 4 #####################################
  # Reduce times to hours, convert to integers
  final_format = function(data){
    data$timeIN = format(data$timeIN, "%H")
    data$timeIN = as.integer(data$timeIN)
    return(data)
  }
  
##############################################################################
# LATENESS METRICS CALCULATION:
##############################################################################
  
  # Diagnostics Function: Runs Lateness Analysis and outputs
  # Net Average Lateness (Raw and Normalized) by Subgroup
  Diagnostics <- function(Data, RawThreshold = 5, NormThreshold = 0.01){
    # Get Global Norms
    GlobalAvg = mean(Data$late_by, na.rm = TRUE)
    GlobalNorm = mean(Data$normalized_intervalDiff, na.rm = TRUE)
    
    # Get Problem Categories
    TimeScores = TimeProblems(Data = Data, NormThreshold = NormThreshold, RawThreshold = RawThreshold, globalAvg = GlobalAvg, globalNorm = GlobalNorm)
    EmployeeScores = EmployeeProblems(Data = Data, NormThreshold = NormThreshold, RawThreshold = RawThreshold, globalAvg = GlobalAvg, globalNorm = GlobalNorm)
    WingScores = WingProblems(Data = Data, NormThreshold = NormThreshold, RawThreshold = RawThreshold, globalAvg = GlobalAvg, globalNorm = GlobalNorm)
    SeverityScores = SeverityProblems(Data = Data, NormThreshold = NormThreshold, RawThreshold = RawThreshold, globalAvg = GlobalAvg, globalNorm = GlobalNorm)
    
    # Print Problem Categories
    cat("\n\nProblem Times:\n")
    print(TimeScores)
    
    cat("\nProblem Employees:\n")
    print(EmployeeScores)
    
    cat("\nProblem Wings:\n")
    print(WingScores)
    
    cat("\nProblem Severities:\n")
    print(SeverityScores)
  }
  
  # Create overlapping histograms for a subset and the full set of data,
  # measuring the raw late time
  CompareGraphRaw <- function(Data, SubData, bins){
    ggplot() +
      geom_histogram(data = Data, aes(x = late_by, y = after_stat(density), fill = "Full Data"), alpha = 0.5, bins = bins) +
      geom_histogram(data = SubData, aes(x = late_by, y = after_stat(density), fill = "Selected Data"), alpha = 0.5, bins = bins) +
      scale_fill_manual(values = c("Full Data" = "black", "Selected Data" = "red"))
  }
  
  # Create overlapping histograms for a subset and the full set of data,
  # measuring the normalized late time
  CompareGraphNorm <- function(Data, SubData, bins){
    ggplot() +
      geom_histogram(data = Data, aes(x = normalized_intervalDiff, y = after_stat(density), fill = "Full Data"), alpha = 0.5, bins = bins) +
      geom_histogram(data = SubData, aes(x = normalized_intervalDiff, y = after_stat(density), fill = "Selected Data"), alpha = 0.5, bins = bins) +
      scale_fill_manual(values = c("Full Data" = "black", "Selected Data" = "red"))
  }
  
  # Get the subset via a given identifier
  # time (0-23, representing hour)
  # employee (an Employee_ID string)
  # wing (A wing [MW, RW, SW, MATW])
  # Severity Level [2, 3, 4, 5]
  # Subset only includes rows for late_by and normalized_intervalDiff, to save space
  ReturnSelected <- function(Data, TimeIN = NULL, EmployeeIN = NULL, WingIN = NULL, SeverityIN = NULL){
    # Invalid Argument
    if(is.null(TimeIN) && is.null(EmployeeIN) && is.null(WingIN) && is.null(SeverityIN)){
      print("THIS IS A BAD SIGN")
      stop()
    }
    
    #time
    if(!is.null(TimeIN)){
      SubData = Data %>% filter(TimeIN == timeIN)
    }
    
    #employee
    if(!is.null(EmployeeIN)){
      SubData = Data %>% filter(Employee_ID == EmployeeIN)
    }
    
    #Wing
    if(!is.null(WingIN)){
      SubData = Data %>% filter(grepl(WingIN,Employee_ID))
    }
    
    #Severity
    if(!is.null(SeverityIN)){
      SubData = Data %>% filter(Severity == SeverityIN)
    }
    return(SubData %>% select(late_by, normalized_intervalDiff, Severity))
  }
  
  # Find the scores for each time
  TimeProblems <- function(Data, RawThreshold = 0, NormThreshold = 0, globalAvg = 0, globalNorm = 0) {
    results <- data.frame(
      Time = integer(),
      LatenessScoreRaw = numeric(),
      LatenessScoreNorm = numeric(),
      RawThresholdReached = logical(),
      NormThresholdReached = logical(),
      stringsAsFactors = FALSE
    )
    
    # Loop through each hour (0–23)
    for (t in 0:23) {
      subdata <- ReturnSelected(Data, TimeIN = t)
      
      raw_score <- LatenessScoreRaw(globalAvg = globalAvg, SubData = subdata)
      norm_score <- LatenessScoreNorm(globalNorm = globalNorm, SubData = subdata)
      
      results <- rbind(
        results,
        data.frame(
          Time = t,
          LatenessScoreRaw = raw_score,
          LatenessScoreNorm = norm_score,
          RawThresholdReached = raw_score > RawThreshold,
          NormThresholdReached = norm_score > NormThreshold
        )
      )
    }
    
    return(results)
  }
  
  # Find employees that exceed threshold
  EmployeeProblems <- function(Data, NormThreshold = 0, RawThreshold = 0, globalAvg = 0, globalNorm = 0){
    # Split data by employee
    e_split <- split(Data, Data$Employee_ID)
    
    # Initialize vectors
    employee_ids <- names(e_split)
    raw_scores <- numeric(length(e_split))
    norm_scores <- numeric(length(e_split))
    raw_flags <- logical(length(e_split))
    norm_flags <- logical(length(e_split))
    
    # Loop over each employee's subset
    for (i in seq_along(e_split)) {
      e_data <- e_split[[i]]
      
      # Compute lateness scores
      raw_score <- LatenessScoreRaw(globalAvg = globalAvg, SubData = e_data)
      norm_score <- LatenessScoreNorm(globalNorm = globalNorm, SubData = e_data)
      
      # Store results
      raw_scores[i] <- raw_score
      norm_scores[i] <- norm_score
      raw_flags[i] <- raw_score > RawThreshold
      norm_flags[i] <- norm_score > NormThreshold
    }
    
    # Build data frame
    e_scores <- data.frame(
      Employee_ID = employee_ids,
      LatenessScoreRaw = raw_scores,
      LatenessScoreNorm = norm_scores,
      RawThresholdReached = raw_flags,
      NormThresholdReached = norm_flags
    )
    
    return(e_scores)
  }
  # Find wings that exceed threshold
  WingProblems <- function(Data, RawThreshold = 0, NormThreshold = 0, globalAvg = 0, globalNorm = 0) {
    # Split data by Wing
    wing_groups <- split(Data, Data$Wing)
    
    results <- data.frame(
      Wing = character(),
      LatenessScoreRaw = numeric(),
      LatenessScoreNorm = numeric(),
      RawThresholdReached = logical(),
      NormThresholdReached = logical(),
      stringsAsFactors = FALSE
    )
    
    # Loop through each subset
    for (w in names(wing_groups)) {
      subdata <- wing_groups[[w]]
      
      raw_score <- LatenessScoreRaw(globalAvg = globalAvg, SubData = subdata)
      norm_score <- LatenessScoreNorm(globalNorm = globalNorm, SubData = subdata)
      
      results <- rbind(
        results,
        data.frame(
          Wing = w,
          LatenessScoreRaw = raw_score,
          LatenessScoreNorm = norm_score,
          RawThresholdReached = raw_score > RawThreshold,
          NormThresholdReached = norm_score > NormThreshold
        )
      )
    }
    
    return(results)
  }
  
  # Find Severities that exceed threshold
  SeverityProblems <- function(Data, RawThreshold = 0, NormThreshold = 0, globalAvg = 0, globalNorm = 0) {
    # Split data by Severity (assumed values: 2, 3, 4, 5)
    severity_groups <- split(Data, Data$Severity)
    
    results <- data.frame(
      Severity = integer(),
      LatenessScoreRaw = numeric(),
      LatenessScoreNorm = numeric(),
      RawThresholdReached = logical(),
      NormThresholdReached = logical(),
      stringsAsFactors = FALSE
    )
    
    for (s in names(severity_groups)) {
      subdata <- severity_groups[[s]]
      
      raw_score <- LatenessScoreRaw(globalAvg = globalAvg, SubData = subdata)
      norm_score <- LatenessScoreNorm(globalNorm = globalNorm, SubData = subdata)
      
      results <- rbind(
        results,
        data.frame(
          Severity = as.integer(s),
          LatenessScoreRaw = raw_score,
          LatenessScoreNorm = norm_score,
          RawThresholdReached = raw_score > RawThreshold,
          NormThresholdReached = norm_score > NormThreshold
        )
      )
    }
    
    return(results)
  }
  
  # LatenessScoreRaw: Return a score of the lateness (magnitude) of a subgroup
  # The score is the number of minutes greater the average lateness 
  # of the subset is above the average lateness of the total dataset
  LatenessScoreRaw <- function(globalAvg = 0, SubData){
    #compute values
    avg = mean(SubData$late_by, na.rm = TRUE)
    sd = sd(SubData$late_by, na.rm = TRUE)
    
    #compute score
    return (avg-globalAvg)
  }
  
  
  # LatenessScoreNorm: Return a score of the lateness (percent) of a subgroup
  # The score is how much greater the average percent lateness 
  # of the subset is above the average percent lateness of the total dataset
  LatenessScoreNorm <- function(globalNorm = 0, SubData){
    #compute values
    avg = mean(SubData$normalized_intervalDiff, na.rm = TRUE)
    sd = sd(SubData$normalized_intervalDiff, na.rm = TRUE)
    
    #compute score
    return ((avg-globalNorm))
  }
  
  