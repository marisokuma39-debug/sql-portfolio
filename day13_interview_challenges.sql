-- =============================================
-- DAY 13: Real Interview Challenges
-- Dataset: City General Hospital (hospital_db)
-- =============================================

-- Challenge 1: Total patients per gender
SELECT 
  gender,
  COUNT(*) AS total_patients
FROM patients
GROUP BY gender;

-- Challenge 2: Emergency admissions with Critical diagnosis
SELECT 
  p.first_name,
  p.last_name,
  a.admission_type,
  d.severity,
  d.diagnosis
FROM patients p
JOIN admissions a ON p.patient_id   = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
WHERE a.admission_type = 'Emergency'
AND d.severity = 'Critical';

-- Challenge 3: Average, min and max bill per payment status
SELECT 
  payment_status,
  AVG(total_amount) AS avg_bill,
  MIN(total_amount) AS min_bill,
  MAX(total_amount) AS max_bill
FROM billing
GROUP BY payment_status;

-- Challenge 4: Doctors with more than 1 patient
SELECT 
  first_name,
  speciality,
  COUNT(*) AS total_patients
FROM doctors
JOIN admissions ON doctors.doctor_id = admissions.doctor_id
GROUP BY first_name, speciality
HAVING COUNT(*) > 1
ORDER BY total_patients DESC;

-- Challenge 5: Most expensive bill per department
WITH ranked_bills AS (
  SELECT 
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    dep.dept_name,
    d.diagnosis,
    b.total_amount,
    RANK() OVER (
      PARTITION BY dep.dept_id 
      ORDER BY b.total_amount DESC
    ) AS dept_rank
  FROM admissions a
  JOIN patients p      ON a.patient_id   = p.patient_id
  JOIN departments dep ON a.dept_id      = dep.dept_id
  JOIN diagnoses d     ON a.admission_id = d.admission_id
  JOIN billing b       ON a.admission_id = b.admission_id
)
SELECT 
  patient_name,
  dept_name,
  diagnosis,
  total_amount
FROM ranked_bills
WHERE dept_rank = 1
ORDER BY total_amount DESC;

-- Challenge 6: Patients with above average length of stay
SELECT 
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  d.diagnosis,
  a.admission_type,
  DATEDIFF(
    COALESCE(a.discharge_date, CURDATE()),
    a.admission_date
  ) AS length_of_stay
FROM patients p
JOIN admissions a ON p.patient_id   = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
WHERE DATEDIFF(
    COALESCE(a.discharge_date, CURDATE()),
    a.admission_date
  ) > (
  SELECT AVG(DATEDIFF(COALESCE(discharge_date, CURDATE()), admission_date))
  FROM admissions
)
ORDER BY length_of_stay DESC;

-- Challenge 7: Monthly revenue trend with classification
WITH monthly_revenue AS (
  SELECT 
    DATE_FORMAT(a.admission_date, '%Y-%m') AS month,
    SUM(b.total_amount)                    AS monthly_revenue
  FROM admissions a
  JOIN billing b ON a.admission_id = b.admission_id
  WHERE YEAR(a.admission_date) = 2024
  GROUP BY DATE_FORMAT(a.admission_date, '%Y-%m')
),
revenue_with_lag AS (
  SELECT 
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month) AS prev_month_revenue,
    monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month) AS revenue_change
  FROM monthly_revenue
)
SELECT 
  month,
  monthly_revenue,
  prev_month_revenue,
  revenue_change,
  CASE
    WHEN revenue_change > 0 THEN 'Growth'
    WHEN revenue_change < 0 THEN 'Decline'
    WHEN revenue_change = 0 THEN 'Stable'
    ELSE 'First Month'
  END AS trend
FROM revenue_with_lag
ORDER BY month;

-- Challenge 8: Top 2 highest paid doctors per department
WITH doctor_ranked AS (
  SELECT 
    dep.dept_name,
    CONCAT(doc.first_name, ' ', doc.last_name) AS doctor_name,
    doc.speciality,
    doc.salary,
    RANK() OVER (
      PARTITION BY dep.dept_id 
      ORDER BY doc.salary DESC
    ) AS dept_rank
  FROM doctors doc
  JOIN departments dep ON doc.dept_id = dep.dept_id
)
SELECT 
  dept_name,
  doctor_name,
  speciality,
  salary
FROM doctor_ranked
WHERE dept_rank <= 2
ORDER BY dept_name, salary DESC;