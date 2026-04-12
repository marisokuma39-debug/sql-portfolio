-- =============================================
-- DAY 14: Healthcare Capstone Project
-- City General Hospital — Board Performance Report
-- Dataset: hospital_db
-- Analyst: Ogoma Maris Okuma
-- =============================================

-- =============================================
-- REPORT 1: Patient Demographics
-- =============================================

-- 1A: Patient distribution by age group
SELECT 
  CASE
    WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 18 THEN 'Pediatric (0-17)'
    WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 40 THEN 'Young Adult (18-39)'
    WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 65 THEN 'Middle Aged (40-64)'
    ELSE 'Elderly (65+)'
  END                                                           AS age_group,
  COUNT(*)                                                      AS total_patients,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patients), 1) AS percentage
FROM patients
GROUP BY age_group
ORDER BY total_patients DESC;

-- 1B: Patient distribution by country
SELECT 
  country,
  COUNT(*) AS total_patients
FROM patients
GROUP BY country
ORDER BY total_patients DESC;

-- 1C: Blood type distribution
SELECT 
  blood_type,
  COUNT(*)                                                      AS total_patients,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patients), 1) AS percentage
FROM patients
GROUP BY blood_type
ORDER BY total_patients DESC;

-- =============================================
-- REPORT 2: Clinical Performance
-- =============================================

-- 2A: Cases by severity level
SELECT 
  severity,
  COUNT(*)                                                         AS total_cases,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM diagnoses), 1)   AS percentage
FROM diagnoses
GROUP BY severity
ORDER BY total_cases DESC;

-- 2B: Average length of stay by admission type
SELECT 
  admission_type,
  COUNT(*)  AS total_admissions,
  ROUND(AVG(DATEDIFF(
    COALESCE(discharge_date, CURDATE()),
    admission_date
  )), 1)    AS avg_length_of_stay
FROM admissions
GROUP BY admission_type
ORDER BY avg_length_of_stay DESC;

-- 2C: All diagnoses sorted by severity
SELECT 
  diagnosis,
  severity
FROM diagnoses
ORDER BY 
  CASE severity
    WHEN 'Critical' THEN 1
    WHEN 'Severe'   THEN 2
    WHEN 'Moderate' THEN 3
    WHEN 'Mild'     THEN 4
  END;

-- =============================================
-- REPORT 3: Financial Performance
-- =============================================

-- 3A: Overall financial summary
SELECT 
  SUM(total_amount)                    AS total_billed,
  SUM(insurance_cover)                 AS total_insurance,
  SUM(total_amount - insurance_cover)  AS patient_liability,
  SUM(CASE WHEN payment_status = 'Paid' 
      THEN total_amount ELSE 0 END)    AS total_collected,
  SUM(CASE WHEN payment_status = 'Pending' 
      THEN total_amount ELSE 0 END)    AS total_pending
FROM billing;

-- 3B: Revenue by department
SELECT 
  dep.dept_name,
  COUNT(a.admission_id)      AS total_patients,
  SUM(b.total_amount)        AS total_revenue,
  ROUND(AVG(b.total_amount)) AS avg_bill_per_patient
FROM departments dep
JOIN admissions a ON dep.dept_id    = a.dept_id
JOIN billing b    ON a.admission_id = b.admission_id
GROUP BY dep.dept_id, dep.dept_name
ORDER BY total_revenue DESC;

-- 3C: Outstanding payments report
SELECT 
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  d.diagnosis,
  b.total_amount,
  b.insurance_cover,
  b.total_amount - b.insurance_cover      AS patient_owes,
  b.payment_status
FROM patients p
JOIN admissions a ON p.patient_id   = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
JOIN billing b    ON a.admission_id = b.admission_id
WHERE b.payment_status IN ('Pending', 'Partial')
ORDER BY b.total_amount DESC;

-- =============================================
-- REPORT 4: Doctor Workload
-- =============================================

-- 4A: Patient load per doctor
SELECT 
  CONCAT(doc.first_name, ' ', doc.last_name) AS doctor_name,
  doc.speciality,
  COUNT(a.admission_id)                       AS patients_treated,
  SUM(b.total_amount)                         AS revenue_generated
FROM doctors doc
JOIN admissions a ON doc.doctor_id  = a.doctor_id
JOIN billing b    ON a.admission_id = b.admission_id
GROUP BY doc.doctor_id, doc.first_name, doc.last_name, doc.speciality
ORDER BY patients_treated DESC;

-- 4B: Doctor salary vs revenue generated
WITH doctor_performance AS (
  SELECT 
    CONCAT(doc.first_name, ' ', doc.last_name) AS doctor_name,
    doc.speciality,
    doc.salary,
    COUNT(a.admission_id)                       AS patients_treated,
    SUM(b.total_amount)                         AS revenue_generated
  FROM doctors doc
  JOIN admissions a ON doc.doctor_id  = a.doctor_id
  JOIN billing b    ON a.admission_id = b.admission_id
  GROUP BY doc.doctor_id, doc.first_name, doc.last_name,
           doc.speciality, doc.salary
)
SELECT 
  doctor_name,
  speciality,
  salary,
  revenue_generated,
  revenue_generated - salary AS net_contribution,
  CASE
    WHEN revenue_generated > salary THEN 'Revenue Positive'
    WHEN revenue_generated = salary THEN 'Break Even'
    ELSE 'Revenue Negative'
  END AS financial_status
FROM doctor_performance
ORDER BY net_contribution DESC;

-- =============================================
-- REPORT 5: Department Efficiency
-- =============================================

WITH dept_metrics AS (
  SELECT 
    dep.dept_name,
    COUNT(a.admission_id)   AS total_admissions,
    SUM(b.total_amount)     AS total_revenue,
    AVG(b.total_amount)     AS avg_revenue_per_case,
    ROUND(AVG(DATEDIFF(
      COALESCE(a.discharge_date, CURDATE()),
      a.admission_date
    )), 1)                  AS avg_length_of_stay,
    SUM(CASE WHEN b.payment_status = 'Paid' 
        THEN 1 ELSE 0 END)  AS paid_cases,
    COUNT(a.admission_id) - 
    SUM(CASE WHEN b.payment_status = 'Paid' 
        THEN 1 ELSE 0 END)  AS unpaid_cases
  FROM departments dep
  JOIN admissions a ON dep.dept_id    = a.dept_id
  JOIN billing b    ON a.admission_id = b.admission_id
  GROUP BY dep.dept_id, dep.dept_name
)
SELECT 
  dept_name,
  total_admissions,
  total_revenue,
  ROUND(avg_revenue_per_case)   AS avg_revenue_per_case,
  avg_length_of_stay,
  paid_cases,
  unpaid_cases,
  CASE
    WHEN unpaid_cases = 0                    THEN 'Excellent'
    WHEN unpaid_cases <= total_admissions/2  THEN 'Good'
    ELSE                                          'Needs Attention'
  END AS collection_status
FROM dept_metrics
ORDER BY total_revenue DESC;

-- =============================================
-- REPORT 6: Risk & Quality
-- =============================================

-- 6A: Long stay patients still admitted
SELECT 
  CONCAT(p.first_name, ' ', p.last_name)    AS patient_name,
  d.diagnosis,
  d.severity,
  a.admission_type,
  DATE_FORMAT(a.admission_date, '%M %d, %Y') AS admitted_on,
  DATEDIFF(CURDATE(), a.admission_date)      AS days_admitted,
  b.payment_status
FROM patients p
JOIN admissions a ON p.patient_id   = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
JOIN billing b    ON a.admission_id = b.admission_id
WHERE a.discharge_date IS NULL
ORDER BY days_admitted DESC;

-- 6B: Patients with no medication recorded
SELECT 
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  d.diagnosis,
  d.severity,
  a.admission_type
FROM patients p
JOIN admissions a ON p.patient_id   = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
WHERE NOT EXISTS (
  SELECT 1 
  FROM medications m 
  WHERE m.admission_id = a.admission_id
)
ORDER BY d.severity DESC;

-- 6C: Blood type demand assessment
SELECT 
  blood_type,
  COUNT(*) AS patients_needing,
  CASE
    WHEN COUNT(*) >= 3 THEN 'High Demand — Stock Priority'
    WHEN COUNT(*) = 2  THEN 'Moderate Demand — Monitor'
    ELSE                    'Low Demand — Standard Stock'
  END AS blood_bank_priority
FROM patients
GROUP BY blood_type
ORDER BY patients_needing DESC;

-- =============================================
-- REPORT 7: Executive Summary
-- =============================================

WITH 
patient_stats AS (
  SELECT 
    COUNT(*)                                                    AS total_patients,
    SUM(CASE WHEN gender = 'Male'   THEN 1 ELSE 0 END)         AS male_patients,
    SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END)         AS female_patients,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE())))  AS avg_age
  FROM patients
),
admission_stats AS (
  SELECT 
    COUNT(*)                                                         AS total_admissions,
    SUM(CASE WHEN admission_type = 'Emergency'  THEN 1 ELSE 0 END)  AS emergency,
    SUM(CASE WHEN admission_type = 'Elective'   THEN 1 ELSE 0 END)  AS elective,
    SUM(CASE WHEN admission_type = 'Outpatient' THEN 1 ELSE 0 END)  AS outpatient,
    SUM(CASE WHEN discharge_date IS NULL        THEN 1 ELSE 0 END)  AS still_admitted
  FROM admissions
),
financial_stats AS (
  SELECT 
    SUM(total_amount)                                           AS total_billed,
    SUM(insurance_cover)                                        AS total_insurance,
    SUM(CASE WHEN payment_status = 'Paid' 
        THEN total_amount ELSE 0 END)                          AS total_collected,
    SUM(CASE WHEN payment_status = 'Pending' 
        THEN total_amount ELSE 0 END)                          AS total_pending,
    ROUND(AVG(total_amount))                                    AS avg_bill
  FROM billing
),
clinical_stats AS (
  SELECT 
    SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END)     AS critical_cases,
    SUM(CASE WHEN severity = 'Severe'   THEN 1 ELSE 0 END)     AS severe_cases,
    SUM(CASE WHEN severity = 'Moderate' THEN 1 ELSE 0 END)     AS moderate_cases,
    SUM(CASE WHEN severity = 'Mild'     THEN 1 ELSE 0 END)     AS mild_cases
  FROM diagnoses
)
SELECT 
  p.total_patients,
  p.male_patients,
  p.female_patients,
  p.avg_age                                                     AS avg_patient_age,
  a.total_admissions,
  a.emergency,
  a.elective,
  a.outpatient,
  a.still_admitted,
  f.total_billed,
  f.total_collected,
  f.total_pending,
  f.avg_bill,
  c.critical_cases,
  c.severe_cases,
  c.moderate_cases,
  c.mild_cases
FROM patient_stats p
CROSS JOIN admission_stats a
CROSS JOIN financial_stats f
CROSS JOIN clinical_stats c;