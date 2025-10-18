# SYSEN-5300-HACKATHON — Tim’s Left Foot

Hackathon Competition – 10/17/2025

## 🧠 Team Members

- Zibin Song
- Jackson Kollmorgen
- Qicheng Fu
- Cami Chan
- Aras Ozdemir


## 🧩 Prompt 3: Health Systems

Hospitals require the coordination of many nurses and doctors on each floor for good communication and treatment of patients. However, in your hospital system, patients note wide and irregular gaps and how often nurses and doctors come to check on them during their inpatient care, impacting perceived and actual quality of treatment, and sometimes extending the stay of patients unnecessarily. Your hospital system has commissioned your team to develop a quality control system for tracking and mitigating wait times for inpatient care while on the hospital floor.



## 🗂️ Data Set Explanation

The following project includes 2 datasets based on real life hospitals.

### 📘 Data Set 1: 
The first hospital has an estimated 1100 patients per 10 days and is based on University of San Francisco (UCSF) Hospital. It includes four wings: 
1. Surgical wing - SW 
2. Medical Ward - MW 
3. Maternity Ward - MATW 
4. Recovery wing - RW 

It also features 140 healthcare providers, of which are 40 doctors and 100 are nurses. The following schedule (Schedule 1 Big Hospital) is implemented for the healthcare providers: 

- Morning: 00:00:00 - 8:00:00 2 Doctors,5 Nurses Per Wing (28 Healthcare Providers on duty)
- Day Time: 8:00:00 - 16:00:00 4 Doctors, 10 Nurses Per Wing (56 Healthcare Providers on duty)
- Evening Time: 16:00:00 - 24:00:00 4 Doctors, 10 Nurses Per Wing (56 Healthcare Providers on duty)

### 📘 Data Set 2: 
The second hospital has an estimated 550 patients per 10 days and is based on Good Samaritan Hospital in San Jose, California. It includes four wings: 
1. Surgical wing - SW 
2. Medical Ward - MW
3. Maternity Ward - MATW 
4. Recovery wing - RW

It also features 140 healthcare providers, of which 40 are doctors and 100 are nurses. The following schedule (Schedule 2 Medium Hospital) is implemented for the healthcare providers: 
- Morning: 00:00:00 - 8:00:00 1D,3N Per Wing = 4 
- Day Time: 8:00:00 - 16:00:00 2D, 5N Per Wing = 7
- Evening Time: 16:00:00 - 24:00:00 2D,5N Per Wing = 7

## 🎯 Objective

The objective of this project is to design a quality control system that monitors and minimizes wait times for inpatient care through data-driven insights and predictive scheduling models.

## ⚙️ Methodology / Approach
When a patient checks in, their basic information and demographics will be recorded. They will also be assigned a severity level based on the Emergency Severity Index (ESI) system which is the triage system used in the U.S. to categorize and prioritize patients based on their level of emergency and current condition. Hospitals will be able to determine how frequently each patient will be checked in on (e.g. every 2 hours, every 30 minutes). 

*Note: Severity Level 1 requires constant monitoring of patients and is therefore excluded from our datasets.


Caregivers (e.g. nurses and doctors) will have unique IDs that can scan into a patient's room which will log the date, time, employee, patient, and room at the time of each scan. For every patient visit (check-in), the caregiver will scan into the room. By collecting this data, our tool will evaluate the actual time interval between caregiver check-ins for each patient and compare it to the expected frequency determined at the time of the patient's initial check-in. This comparison, represented by the difference between the actual and expected time interval, would ideally result in a value of 0 which means the actual time interval is the same as the expected time interval.
*Note: If a caregiver visits a patient early (where the actual time interval is less than the expected time interval), then there is no lateness and the difference between the actual and expected time will be considered to be 0. 

Our tool will enable hospitals to easily collect and view their patients' wait times by interacting with a user-friendly dashboard that displays the data as histograms based on different subgroups. When data exceeds [CONTROL LIMIT?], the data will be flagged and the dashboard will output a notification for the hospital to review and address.  

~~~mermaid
flowchart TD
    A(Patient checks into hospital) -->|records patient info, e.g. gender, DoB, Patient_ID, Severity, Room Number, expected frequency interval| B[Data]
    B --> C(Caregiver scans into the room for each patient visit)
    C --> |date, timestamp, and employee ID collected for each scan in| D(Our Functions)
    C --> B
    D --> |calculates time interval between caregiver visits to patients & how late caregivers are to check in with patients|B
    B --> |data cleaning|E(Plots)
    E --> F(Dashboard)
    F --> |visualizes data by subgroups & flags potential factors for lateness| G(Informs hospital staff)

   style D fill:#f9f,stroke:#333,stroke-width:3px
      style E fill:#f9f,stroke:#333,stroke-width:3px
         style F fill:#f9f,stroke:#333,stroke-width:3px
                  style B fill:#fff,stroke:#333,stroke-width:3px
~~~



Briefly describe how you plan to solve the problem.
For example:

Analyzed patient wait-time data using Python (pandas, NumPy).

Implemented time-based and resource allocation models.

Developed visual dashboards using Power BI or Matplotlib to track provider coverage and response times.

Proposed a predictive model for optimal staffing levels.

## 💻 Tools and Technologies

Languages: R

Libraries: p

Visualization: 

Version Control: GitHub

## 📊 Expected Outcomes

Reduced patient wait-time variability.

Improved staff utilization rates.

Increased patient satisfaction scores through better coverage.

## 📁 Project Structure

Show the layout of your repo for clarity:

├── data/
│   ├── hospital_big.csv
│   ├── hospital_medium.csv
├── scripts/
│   ├── analysis.ipynb
├── results/
│   ├── wait_time_analysis.png
├── README.md


## 📜 References

https://www.goodsamsanjose.com/?sc_lang=en-US

https://www.ucsfhealth.org
