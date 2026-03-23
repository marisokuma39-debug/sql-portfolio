-- =============================================
-- DAY 8: String & Date Functions
-- Dataset: City General Hospital (hospital_db)
-- =============================================

-- UPPER and LOWER: standardize name casing
SELECT 
  UPPER(first_name) AS first_name,
  UPPER(last_name)  AS last_name
FROM patients;

-- TRIM: detect and remove accidental spaces
SELECT 
  first_name,
  TRIM(first_name)         AS trimmed_name,
  LENGTH(first_name)       AS raw_length,
  LENGTH(TRIM(first_name)) AS trimmed_length
FROM patients;

-- LENGTH: validate phone number format
SELECT 
  first_name,
  last_name,
  phone,
  LENGTH(phone) AS phone_length
FROM patients
WHERE LENGTH(phone) != 11;

-- CONCAT: build patient labels
SELECT 
  CONCAT(first_name, ' ', last_name) AS patient_name,
  CONCAT(city, ', ', country)        AS location,
  CONCAT(blood_type, ' blood type')  AS blood_info
FROM patients;

-- SUBSTRING: extract area code from phone
SELECT 
  first_name,
  phone,
  SUBSTRING(phone, 1, 4) AS area_code,
  SUBSTRING(phone, 5, 7) AS number
FROM patients;

-- REPLACE: standardize medical terminology
SELECT 
  diagnosis,
  REPLACE(diagnosis, 'Cancer', 'Malignant Neoplasm') AS standardized_diagnosis
FROM diagnoses;

-- CURDATE and NOW: current date and time
SELECT 
  CURDATE() AS todays_date,
  NOW()     AS current_datetime;

-- YEAR MONTH DAY: extract date parts
SELECT 
  first_name,
  last_name,
  date_of_birth,
  YEAR(date_of_birth)  AS birth_year,
  MONTH(date_of_birth) AS birth_month,
  DAY(date_of_birth)   AS birth_day
FROM patients;

-- Filter elderly patients born before 1970
SELECT 
  first_name,
  last_name,
  date_of_birth,
  YEAR(date_of_birth) AS birth_year
FROM patients
WHERE YEAR(date_of_birth) < 1970
ORDER BY date_of_birth ASC;

-- TIMESTAMPDIFF: calculate exact patient age
SELECT 
  first_name,
  last_name,
  date_of_birth,
  TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) AS age_years
FROM patients
ORDER BY age_years DESC;

-- DATEDIFF: calculate length of stay
SELECT 
  p.first_name,
  p.last_name,
  a.admission_date,
  a.discharge_date,
  DATEDIFF(a.discharge_date, a.admission_date) AS length_of_stay_days
FROM patients p
JOIN admissions a ON p.patient_id = a.patient_id
WHERE a.discharge_date IS NOT NULL
ORDER BY length_of_stay_days DESC;

-- DATE_FORMAT: format dates for reports
SELECT 
  p.first_name,
  p.last_name,
  a.admission_date,
  DATE_FORMAT(a.admission_date, '%M %d, %Y') AS formatted_date,
  DATE_FORMAT(a.admission_date, '%M %Y')     AS month_year,
  DATE_FORMAT(a.admission_date, '%d/%m/%Y')  AS uk_format
FROM patients p
JOIN admissions a ON p.patient_id = a.patient_id;

-- FULL PATIENT SUMMARY: combining all functions
SELECT 
  CONCAT(p.first_name, ' ', p.last_name)         AS patient_name,
  TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,
  p.gender,
  p.blood_type,
  CONCAT(p.city, ', ', p.country)                 AS location,
  DATE_FORMAT(a.admission_date, '%M %d, %Y')      AS admitted_on,
  a.admission_type,
  DATEDIFF(
    COALESCE(a.discharge_date, CURDATE()),
    a.admission_date
  )                                                AS days_in_hospital,
  d.diagnosis,
  d.severity
FROM patients p
JOIN admissions a ON p.patient_id  = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
ORDER BY days_in_hospital DESC;
