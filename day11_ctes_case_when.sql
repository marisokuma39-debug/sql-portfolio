-- =============================================
-- DAY 11: CTEs and CASE WHEN
-- Dataset: City General Hospital (hospital_db)
-- =============================================

-- CASE WHEN: classify diagnosis severity into clinical priority
SELECT 
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  d.diagnosis,
  d.severity,
  CASE
    WHEN d.severity = 'Critical' THEN 'Immediate — ICU Review'
    WHEN d.severity = 'Severe'   THEN 'Urgent — Consultant Review'
    WHEN d.severity = 'Moderate' THEN 'Standard — Ward Review'
    WHEN d.severity = 'Mild'     THEN 'Routine — GP Follow Up'
    ELSE 'Unclassified'
  END AS clinical_action
FROM patients p
JOIN admissions a ON p.patient_id   = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
ORDER BY 
  CASE d.severity
    WHEN 'Critical' THEN 1
    WHEN 'Severe'   THEN 2
    WHEN 'Moderate' THEN 3
    WHEN 'Mild'     THEN 4
  END;

-- CASE WHEN in aggregation: severity pivot per department
SELECT 
  dep.dept_name,
  COUNT(*)                                                    AS total_patients,
  SUM(CASE WHEN d.severity = 'Critical' THEN 1 ELSE 0 END)   AS critical_cases,
  SUM(CASE WHEN d.severity = 'Severe'   THEN 1 ELSE 0 END)   AS severe_cases,
  SUM(CASE WHEN d.severity = 'Moderate' THEN 1 ELSE 0 END)   AS moderate_cases,
  SUM(CASE WHEN d.severity = 'Mild'     THEN 1 ELSE 0 END)   AS mild_cases
FROM departments dep
JOIN admissions a ON dep.dept_id    = a.dept_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
GROUP BY dep.dept_id, dep.dept_name
ORDER BY critical_cases DESC;

-- CASE WHEN: billing classification and action
SELECT 
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  d.diagnosis,
  b.total_amount,
  b.payment_status,
  CASE
    WHEN b.total_amount > 15000 THEN 'High Cost'
    WHEN b.total_amount > 5000  THEN 'Medium Cost'
    ELSE                             'Low Cost'
  END AS cost_category,
  CASE
    WHEN b.payment_status = 'Pending' 
     AND b.total_amount > 10000       THEN 'URGENT COLLECTION'
    WHEN b.payment_status = 'Pending' THEN 'Standard Collection'
    WHEN b.payment_status = 'Partial' THEN 'Payment Plan Review'
    WHEN b.payment_status = 'Paid'    THEN 'Closed'
    ELSE                                   'Waived'
  END AS billing_action
FROM patients p
JOIN admissions a ON p.patient_id   = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
JOIN billing b    ON a.admission_id = b.admission_id
ORDER BY b.total_amount DESC;

-- Single CTE: high cost patients above $5000
WITH high_cost_patients AS (
  SELECT 
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    d.diagnosis,
    d.severity,
    b.total_amount,
    b.payment_status
  FROM patients p
  JOIN admissions a ON p.patient_id   = a.patient_id
  JOIN diagnoses d  ON a.admission_id = d.admission_id
  JOIN billing b    ON a.admission_id = b.admission_id
  WHERE b.total_amount > 5000
)
SELECT 
  patient_name,
  diagnosis,
  severity,
  total_amount,
  payment_status
FROM high_cost_patients
ORDER BY total_amount DESC;

-- Multiple CTEs: full patient profile and classification
WITH 
patient_metrics AS (
  SELECT 
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name)          AS patient_name,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE())  AS age,
    DATEDIFF(
      COALESCE(a.discharge_date, CURDATE()),
      a.admission_date
    )                                                 AS length_of_stay,
    a.admission_type,
    a.admission_id
  FROM patients p
  JOIN admissions a ON p.patient_id = a.patient_id
),
patient_full_profile AS (
  SELECT 
    pm.patient_name,
    pm.age,
    pm.length_of_stay,
    pm.admission_type,
    d.diagnosis,
    d.severity,
    b.total_amount,
    b.payment_status
  FROM patient_metrics pm
  JOIN diagnoses d ON pm.admission_id = d.admission_id
  JOIN billing b   ON pm.admission_id = b.admission_id
),
patient_classified AS (
  SELECT 
    patient_name,
    age,
    length_of_stay,
    diagnosis,
    severity,
    total_amount,
    payment_status,
    CASE
      WHEN age > 65 AND severity IN ('Critical','Severe') THEN 'High Risk Elderly'
      WHEN age > 65                                       THEN 'Elderly Standard'
      WHEN severity = 'Critical'                          THEN 'Critical Young'
      WHEN total_amount > 10000                           THEN 'High Cost'
      ELSE 'Standard'
    END AS patient_category
  FROM patient_full_profile
)
SELECT 
  patient_category,
  COUNT(*)            AS total_patients,
  AVG(age)            AS avg_age,
  AVG(length_of_stay) AS avg_stay_days,
  AVG(total_amount)   AS avg_bill,
  SUM(total_amount)   AS total_revenue
FROM patient_classified
GROUP BY patient_category
ORDER BY total_revenue DESC;

-- CTE with window functions: department billing analysis
WITH 
dept_billing AS (
  SELECT 
    dep.dept_name,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    d.diagnosis,
    b.total_amount
  FROM departments dep
  JOIN admissions a ON dep.dept_id    = a.dept_id
  JOIN patients p   ON a.patient_id   = p.patient_id
  JOIN diagnoses d  ON a.admission_id = d.admission_id
  JOIN billing b    ON a.admission_id = b.admission_id
),
dept_analysis AS (
  SELECT 
    dept_name,
    patient_name,
    diagnosis,
    total_amount,
    AVG(total_amount) OVER (PARTITION BY dept_name) AS dept_avg_bill,
    RANK()            OVER (PARTITION BY dept_name ORDER BY total_amount DESC) AS dept_rank,
    SUM(total_amount) OVER (PARTITION BY dept_name) AS dept_total_revenue
  FROM dept_billing
)
SELECT 
  dept_name,
  patient_name,
  diagnosis,
  total_amount       AS highest_bill,
  dept_avg_bill      AS department_average,
  dept_total_revenue AS department_total
FROM dept_analysis
WHERE dept_rank = 1
ORDER BY dept_total_revenue DESC;

-- COALESCE and NULLIF: safe insurance coverage calculation
WITH billing_summary AS (
  SELECT 
    dep.dept_name,
    COUNT(a.admission_id)                    AS total_admissions,
    SUM(b.total_amount)                      AS total_billed,
    SUM(b.insurance_cover)                   AS total_insurance,
    SUM(b.total_amount) - 
    SUM(b.insurance_cover)                   AS patient_liability,
    ROUND(
      SUM(b.insurance_cover) / 
      NULLIF(SUM(b.total_amount), 0) * 100
    , 1)                                     AS insurance_coverage_pct
  FROM departments dep
  JOIN admissions a ON dep.dept_id    = a.dept_id
  JOIN billing b    ON a.admission_id = b.admission_id
  GROUP BY dep.dept_id, dep.dept_name
)
SELECT 
  dept_name,
  total_admissions,
  total_billed,
  total_insurance,
  COALESCE(patient_liability, 0)        AS patient_liability,
  COALESCE(insurance_coverage_pct, 0)   AS insurance_coverage_pct
FROM billing_summary
ORDER BY insurance_coverage_pct DESC;