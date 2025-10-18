# SYSEN 5300 HACKATHON - Group: Tim’s Left Foot

Hackathon Competition – 10/17/2025 to 10/18/2025

## 🧠 Team Members

- Zibin Song
- Jackson Kollmorgen
- Qicheng Fu
- Cami Chan
- Aras Ozdemir


## 🧩 Prompt 3: Health Systems

Hospitals require the coordination of many nurses and doctors on each floor for good communication and treatment of patients. However, in your hospital system, patients note wide and irregular gaps and how often nurses and doctors come to check on them during their inpatient care, impacting perceived and actual quality of treatment, and sometimes extending the stay of patients unnecessarily. Your hospital system has commissioned your team to develop a quality control system for tracking and mitigating wait times for inpatient care while on the hospital floor.

## 📖 Table of Contents
The following section provides a table of contents outlining all components of our GitHub reprository.


- **Dataset_Locked_UCSF - Patient Intake.csv** — Patient intake dataset  
- **Good_Sam_visits_Mid_Hospital.csv** — Hospital visit dataset  
- **LICENSE** — Contains the MIT license  
- **ShinyAppV6.R** — Interactive dashboard (Shiny App)  
- **.gitignore** — Specifies files to ignore in Git  
- **HospitalWaitTimesDiagnostic.R** — Computes lateness metrics and generates quantities of interest  

**[Documentation Folder/](https://github.com/ZibinSong/SYSEN-5300-HACKATHON---Tim-s-Left-Foot-/tree/main/Documentation%20Folder)**
- **Codebook.md** — Describes all variables and data types used in the code  
- **Documentation.md** — Contains additional information about the code  

**[Data Generation/](https://github.com/ZibinSong/SYSEN-5300-HACKATHON---Tim-s-Left-Foot-/tree/main/Data%20Generation%20Folder)**
- **Data_Generation_CodeGood_Sam_Dataset_Generation.R** — Generates `Good_Sam_visits_Mid_Hospital.csv`  
- **UCSF_DataSet_Generation.R** — Generates `Dataset_Locked_UCSF - Patient Intake.csv`

## ℹ️ How to use our Tool

Our diagnostic tool is provided as a self-contained R Shiny application (`ShinyAppV5.R`), which includes all necessary data loading, processing, and visualization logic.

1.  **Download Required Files**:
    * Download the interactive dashboard file: `ShinyAppV5.R`
    * Download the necessary dataset files: `Dataset_Locked_UCSF - Patient Intake.csv` and `Good_Sam_visits_Mid_Hospital.csv`
    * **Note**: The R code (`ShinyAppV5.R`) expects these CSV files to be in the same working directory or the paths specified within the script (e.g., `/cloud/project/`).

2.  **Install Libraries (if needed)**:
    * Ensure you have the required R packages installed: `shiny`, `shinydashboard`, `plotly`, `DT`, `dplyr`, `tidyr`, `stringr`, `lubridate`, and `readr`.
    * You can install them by running: `install.packages(c("shiny", "shinydashboard", "plotly", "DT", "dplyr", "tidyr", "stringr", "lubridate", "readr"))`

3.  **Run the Dashboard**:
    * Open `ShinyAppV5.R` in RStudio or your preferred R environment.
    * Run the entire script. The last line, `shinyApp(ui, server)`, will automatically launch the interactive dashboard in a web browser or RStudio Viewer pane.

4.  **Analyze and Diagnose**:
    * Use the filters in the left sidebar (Hospital System, Date Range, Metric, Thresholds) to analyze the data.
    * Monitor the **Key Performance Indicators (KPIs)**, the **X-bar Control Chart**, and the **Subset Violating Thresholds** table to identify potential root causes for wait time variability.


## 🎯 Objective

The objective of this project is to design a diagnostic tool that monitors the wait times for inpatient care and identifies potential causes for caregiver "lateness" by using data-driven insights and predictive scheduling models. This will help hospitals understand their possible pain points that lead to irregular or wide gaps between caregiver check-ins that affect their patients' perceived quality of care and patient satisfaction.


## ⚙️ Methodology


### Approach:
1. Create a time-tracking system with scanning cards to monitor caregiver visiting times to patients
2. Outline the process flow, required / collected data inputs, what we want to do with the data, what we want to output
3. Create example datasets for proof of concept
4. Create calculation functions in R
5. Analyze patient wait-time data using data inputs from datasets & the functions created in R
6. Visualize the resulting data using ggplot in R
7. Create visual dashboard to display wait times & notifications 

### Exposition of Process Flow
When a patient checks in, their basic information and demographics will be recorded. They will also be assigned a severity level based on the Emergency Severity Index (ESI) system which is the triage system used in the U.S. to categorize and prioritize patients based on their level of emergency and current condition. Hospitals will be able to determine how frequently each patient will be checked in on (e.g. every 2 hours, every 30 minutes). 

- Note: Severity Level 1 requires constant monitoring of patients and is therefore excluded from our datasets.


Caregivers (e.g. nurses and doctors) will have unique IDs that can scan into a patient's room which will log the date, time, employee, patient, and room at the time of each scan. For every patient visit (aka, check-in), the caregiver will scan into the room. By collecting this data, our tool will evaluate the actual time interval between caregiver check-ins for each patient and compare it to the expected frequency determined at the time of the patient's initial check-in. This comparison, represented by the difference between the actual and expected time interval, would ideally result in a value of 0 which means the actual time interval is the same as the expected time interval.

- *Note: If a caregiver visits a patient early (where the actual time interval is less than the expected time interval), then there is no lateness and the difference between the actual and expected time will be considered to be 0. 


~~~mermaid
flowchart TD
    A(Patient checks into hospital) -->|records patient info, e.g. gender, DoB, Patient_ID, Severity, Room Number, expected frequency interval| B[Data]
    B --> |1|C(Caregiver scans into the room for each patient visit)
    C --> |2 
    date, timestamp, and employee ID collected for each scan in| D(Functions)
    C --> |2|B
    D --> |3
    calculates time interval between caregiver visits to patients & how late caregivers are to check in with patients|B
    B --> |4
    data cleaning|E(Plots)
    E --> F[Dashboard]
    F --> |visualizes data by subgroups & flags potential factors for lateness| G(Informs hospital staff)

   style D fill:#f9f,stroke:#333,stroke-width:3px
      style E fill:#f9f,stroke:#333,stroke-width:3px
         style F fill:#f9f,stroke:#333,stroke-width:3px
                  style B fill:#fff,stroke:#333,stroke-width:3px
~~~

Color Legend: 
- Blue - hospital process steps
- White - stored data
- Pink - our code & tool


## 🗂️ Data Set Explanation

The following project includes 2 datasets based on real life hospitals.

### 📘 Data Set 1: 
The first hospital has an estimated 1100 patients per 10 days and is based on University of San Francisco (UCSF) Hospital. It includes four wings: 
1. Surgical wing - SW 
2. Medical Ward - MW 
3. Maternity Ward - MATW 
4. Recovery wing - RW 

It also features 140 healthcare providers, of which are 40 doctors and 100 are nurses. The following schedule (Schedule 1 Big Hospital) is implemented for the healthcare providers: 

- Morning Shift: 00:00:00 - 8:00:00
    - 7 Healthcare providers Per Wing (28 Healthcare Providers on duty)
- Day Shift: 8:00:00 - 16:00:00
    - 14 Healthcare providers Per Wing (56 Healthcare Providers on duty)
- Evening Shift: 16:00:00 - 24:00:00
    - 14 Healthcare providers Per Wing (56 Healthcare Providers on duty)
 
  Note: It is also important to mention that the healthcare providers are only allowed to work in their shifts and overtime is not assumed.


### 📘 Data Set 2: 
The second hospital has an estimated 550 patients per 10 days and is based on Good Samaritan Hospital in San Jose, California. It includes four wings: 
1. Surgical wing - SW 
2. Medical Ward - MW
3. Maternity Ward - MATW 
4. Recovery wing - RW

It also features 72 healthcare providers. The following schedule (Schedule 2 Medium Hospital) is implemented for the healthcare providers: 
- Morning Shift: 00:00:00 - 8:00:00
    - 4 Healthcare providers Per Wing (4 Healthcare Providers on duty)
- Day Shift: 8:00:00 - 16:00:00
    - 7 Healthcare provider Per Wing (7 Healthcare Providers on duty)
- Evening Shift: 16:00:00 - 24:00:00
    - 7 Healthcare providers Per Wing (7 Healthcare Providers on duty)
 
Note: It is also important to mention that the healthcare providers are only allowed to work in their shifts and overtime is not assumed.

Furthermore, we also added a bias to the second data set. The following rules were implemented into the second data set in order to check our tool's accuracy and detection:
- Employees DSW002 and MMW001 are always late for random between 12-18 minutes
- Wing (Medical Ward (MW) usually recieves late responses by 12-15 minutes) 
- Time of day (from 4:00PM to 6:00PM, all employees have a higher chance to be late, up to max of 8 minutes) due to peak times

Furthermore, we added a maximum possible delay of 25 minutes. 


## 💻 Tools and Technologies

Languages: R

Version Control: GitHub

Our tool will enable hospitals to easily collect and view their patients' wait times by interacting with a user-friendly dashboard that displays the data as histograms based on different subgroups. When data exceeds [CONTROL LIMIT?], the data will be flagged and the dashboard will output a notification for a potential factor that causes lateness which the hospital can then review and address.  


## 📊 Expected Outcomes

This dashboard tool will aid hospitals in performing root-cause analysis for their patient wait-time variability. This helps hospitals reduce patient wait-time variability and dissatisfaction, and track employee performance.

## 🚀 Future improvements

Although we are very proud of our final product, it's only foolish to say that there are no improvments to be made. This section will provide some reference points for future possible improvements to our data.

Future iterations of this project can integrate user satisfaction metrics by comparing perceived lateness with actual recorded wait times. This would help identify psychological or environmental factors—such as stress, patient expectations, or communication delays—that influence patients’ perception of care quality, even when staff performance meets objective standards.

The system could also be improved by accepting additional parameters for data subsets, allowing users to isolate and analyze specific variables such as department, caregiver type, or time of day. This flexibility would enable hospitals to pinpoint the root causes of lateness patterns more effectively.

Incorporating larger patient demographic datasets would further enhance the analysis by uncovering trends related to factors like age, day of the week, or medical condition severity. These insights could help hospitals tailor scheduling strategies to different patient groups for better efficiency and care outcomes.

Finally, the dashboard could be expanded to include interactive filters, customizable alerts, and exportable performance reports. This would create a more dynamic and actionable interface for hospital management, enabling data-driven decisions and continuous improvement in caregiver responsiveness. 



## 📜 References

https://www.goodsamsanjose.com/?sc_lang=en-US

https://www.ucsfhealth.org

https://www.kkfivefingers.com/products/orange-five-finger-running-shoes-rubber-foot-training-shoes-five-toe-shoes/

https://media.emscimprovement.center/documents/Emergency_Severity_Index_Handbook.pdf
