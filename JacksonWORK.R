#install.packages("tidyverse")
#install.packages("truncnorm")
#install.packages("ggplot2")
#library(dplyr)
#library(truncnorm)
#library(ggplot2)

visits = read.csv("metrics 4.csv")
visits$timeIN  = as.POSIXct(visits$timeIN, format = "%Y-%m-%d %H:%M:%S")
visits$timeIN = format(visits$timeIN, "%H")
visits$timeIN = as.integer(visits$timeIN)

#visits %>% distinct(Employee_ID)

testynorm = mean(visits$normalized_intervalDiff, na.rm = TRUE)
testyraw = mean(visits$late_by, na.rm = TRUE)
testysub = ReturnSelected(visits, TimeIN = 2)
testysubnorm = mean(testysub$normalized_intervalDiff, na.rm = TRUE)
testysubraw = mean(testysub$late_by, na.rm = TRUE)
testysubrawsd = sd(testysub$late_by, na.rm = TRUE)
testysubnormsd = sd(testysub$normalized_intervalDiff, na.rm = TRUE)
testyNORMSCORE = (testysubnorm-testynorm)/testysubnormsd
testyRAWSCORE = (testysubraw-testyraw)/testysubrawsd
LatenessScoreNorm(globalNorm = testyavg, SubData = ReturnSelected(visits, TimeIN = 2))
LatenessScoreRaw(globalAvg = testyraw, SubData = ReturnSelected(visits, TimeIN = 2))

Main(Data = visits, useNORM = FALSE, Threshold = 0.00001)
CompareGraphRaw(visits, ReturnSelected(visits, TimeIN = 6), bins = 50)

################################################################################

Main <- function(Data, useNORM = FALSE, Threshold = 3){
  # Get Global Norms
  GlobalAvg = mean(Data$late_by, na.rm = TRUE)
  GlobalNorm = mean(Data$normalized_intervalDiff, na.rm = TRUE)
  
  # Get Problem Categories
  if(useNORM){
    ProblemTimes = TimeProblems(Data = Data, Threshold = Threshold, useNORM = useNORM, global = GlobalNorm)
    ProblemEmployees = EmployeeProblems(Data = Data, Threshold = Threshold, useNORM = useNORM, global = GlobalNorm)
    ProblemWings = WingProblems(Data = Data, Threshold = Threshold, useNORM = useNORM, global = GlobalNorm)
    ProblemSeverities = SeverityProblems(Data = Data, Threshold = Threshold, useNORM = useNORM, global = GlobalNorm)
  }
  else{
    ProblemTimes = TimeProblems(Data = Data, Threshold = Threshold, useNORM = useNORM, global = GlobalAvg)
    ProblemEmployees = EmployeeProblems(Data = Data, Threshold = Threshold, useNORM = useNORM, global = GlobalAvg)
    ProblemWings = WingProblems(Data = Data, Threshold = Threshold, useNORM = useNORM, global = GlobalAvg)
    ProblemSeverities = SeverityProblems(Data = Data, Threshold = Threshold, useNORM = useNORM, global = GlobalAvg)
  }
  # Print Problem Categories
  for (t in ProblemTimes) {
    cat(sprintf("%d:00 - %d:00\n", t, t + 1))
  }
  for (e in ProblemEmployees) {
    print(e)
  }
  for (w in ProblemWings) {
    print(w)
  }
  for (t in ProblemSeverities) {
    print(t)
  }
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
    SubData = Data %>% filter(grepl(WingIN,Room_Number))
  }
  
  #Severity
  if(!is.null(SeverityIN)){
    SubData = Data %>% filter(Severity == SeverityIN)
  }
  return(SubData %>% select(late_by, normalized_intervalDiff))
}

# Find times that exceed threshold
TimeProblems <- function(Data, Threshold = 0, useNORM = FALSE, global = 0){
  if(useNORM){
    t_problems = list()
    for (t in 0:23){
      if(abs(LatenessScoreNorm(globalNorm = global, SubData = ReturnSelected(Data, TimeIN = t))) > Threshold){
        append(t_problems, t)
        print("132")
      }
    }
  }
  else{
    t_problems = list()
    for (t in 0:23){
      if(abs(LatenessScoreRaw(globalAvg = global, SubData = ReturnSelected(Data, TimeIN = t))) > Threshold){
        print("132")
        append(t_problems, t)
      }
    }
  }
  return(t_problems)
}

# Find employees that exceed threshold
EmployeeProblems <- function(Data, Threshold = 0, useNORM = FALSE, global = 0){
  if(useNORM){
    e_problems = list()
    e_split = split(Data, Data$Employee_ID)
    for(e in e_split){
      if(abs(LatenessScoreNorm(globalNorm = global, SubData = e)) > Threshold){
        append(e_problems, e_split$Employee_ID[1])
      }
    }
  }
  else{
    e_problems = list()
    e_split = split(Data, Data$Employee_ID)
    for(e in e_split){
      if(abs(LatenessScoreRaw(globalAvg = global, SubData = e)) > Threshold){
        append(e_problems, e_split$Employee_ID[1])
      }
    }
  }
  return(e_problems)
}

# Find wings that exceed threshold
WingProblems <- function(Data, Threshold = 0, useNORM = FALSE, global = 0){
  if(useNORM){
    w_problems = list()
    for (w in list('MW', 'RW', 'SW', 'MATW')){
      if(LatenessScoreNorm(globalNorm = global, SubData = ReturnSelected(Data, WingIN = w)) > Threshold){
        append(w_problems, w)
      }
    }
  }
  else{
    w_problems = list()
    for (w in list('MW', 'RW', 'SW', 'MATW')){
      if(LatenessScoreRaw(globalAvg = global, SubData = ReturnSelected(Data, WingIN = w)) > Threshold){
        append(w_problems, w)
      }
    }
  }
  return(w_problems)
}

# Find Severities that exceed threshold
SeverityProblems <- function(Data, Threshold = 0, useNORM = FALSE, global = 0){
  if(useNORM){
    t_problems = list()
    for (t in list(2, 3, 4, 5)){
      if(LatenessScoreNorm(globalNorm = global, SubData = ReturnSelected(Data = Data, SeverityIN = t)) > Threshold){
        append(t_problems, t)
      }
    }
  }
  else{
    t_problems = list()
    for (t in list(2, 3, 4, 5)){
      if(LatenessScoreRaw(globalAvg = global, SubData = ReturnSelected(Data = Data, SeverityIN = t)) > Threshold){
        append(t_problems, t)
      }
    }
  }
  return(t_problems)
}

# LatenessScoreRaw: Return a score of the lateness (magnitude) of a subgroup
  # The score is the number of standard deviations the lateness 
  # of the subset is above the average lateness of the total dataset
LatenessScoreRaw <- function(globalAvg = 0, SubData){
  #compute values
  avg = mean(SubData$late_by, na.rm = TRUE)
  sd = sd(SubData$late_by, na.rm = TRUE)
  
  #compute score
  return ((avg-globalAvg)/sd)
}


# LatenessScoreNorm: Return a score of the lateness (percent) of a subgroup
# The score is the number of standard deviations the lateness 
# of the subset is above the average lateness of the total dataset
LatenessScoreNorm <- function(globalNorm = 0, SubData){
  #compute values
  avg = mean(SubData$normalized_intervalDiff, na.rm = TRUE)
  sd = sd(SubData$normalized_intervalDiff, na.rm = TRUE)
  
  #compute score
  return ((avg-globalNorm)/sd)
}

