# SYSEN-5300-HACKATHON — Tim’s Left Foot

Hackathon Competition – 10/17/2025

## 🧠 Team Members

- Zibin Song
- Jackson Kollmorgen
- Qicheng Fu
- Cami Chan
- Aras Ozdemir


## 🧩 Prompt

Prompt 3: Health Systems
Hospitals require the coordination of many nurses and doctors on each floor for good communication and treatment of patients. However, in your hospital system, patients note wide and irregular gaps and how often nurses and doctors come to check on them during their inpatient care, impacting perceived and actual quality of treatment, and sometimes extending the stay of patients unnecessarily. Your hospital system has commissioned your team to develop a quality control system for tracking and mitigating wait times for inpatient care while on the hospital floor.



## 🗂️ Data Set Explanation

The following project includes 2 datasets based on real life hospitals.

### 📘 Data Set 1: 
The first hospital has an estimated 1100 patients per 10 days and is based on University of San Francisco (UCSF) Hospital. it includes four wings: 
1. Surgical wing - SW 
2. Medical Ward - MW 
3. Maternity Ward - MATW 
4. Recovery wing - RW 

and features the following amount of healthcare providers: 140 (of which are 40 doctors and 100 nurses). The following schedule is implemented for the healthcare providers: 
Schedule 1 Big hospital:

- Morning: 00:00:00 - 8:00:00 2 Doctors,5 Nurses Per Wing (28 Healthcare Providers on duty)
- Day Time: 8:00:00 - 16:00:00 4 Doctors, 10 Nurses Per Wing (56 Healthcare Providers on duty)
- Evening Time: 16:00:00 - 24:00:00 4 Doctors, 10 Nurses Per Wing (56 Healthcare Providers on duty)

### 📘 Data Set 2: 
The second hospital has an estimated 550 patients per 10 days and is based on Good Samaritan Hospital in San Jose, California. it includes four wings: 
1. Surgical wing - SW 
2. Medical Ward - MW
3. Maternity Ward - MATW 
4. Recovery wing - RW

and features the following amount of healthcare providers: 140 (of which are 40 doctors and 100 nurses) The following schedule is implemented for the healthcare providers: 
Schedule 2 Medium Sized hospital: 
- Morning: 00:00:00 - 8:00:00 1D,3N Per Wing = 4 
- Day Time: 8:00:00 - 16:00:00 2D, 5N Per Wing = 7
- Evening Time: 16:00:00 - 24:00:00 2D,5N Per Wing = 7

## 🎯 Objective

The objective of this project is to design a quality control system that monitors and minimizes wait times for inpatient care through data-driven insights and predictive scheduling models.

## ⚙️ Methodology / Approach

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

University of San Francisco Hospital public datasets
