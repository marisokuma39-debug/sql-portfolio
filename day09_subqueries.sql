-- =============================================
-- DAY 9: Subqueries
-- Dataset: City General Hospital (hospital_db)
-- =============================================

-- Subquery in WHERE: patients older than average age
SELECT 
  CONCAT(first_name, ' ', last_name) AS patient_name,
  TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) AS age
FROM patients
WHERE TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) > (
  SELECT AVG(TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()))
  FROM patients
)
ORDER BY age DESC;

-- Subquery in WHERE: admissions costing above average
SELECT 
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  d.diagnosis,
  b.total_amount
FROM patients p
JOIN admissions a ON p.patient_id   = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
JOIN billing b    ON a.admission_id = b.admission_id
WHERE b.total_amount > (
  SELECT AVG(total_amount) 
  FROM billing
)
ORDER BY b.total_amount DESC;

-- Subquery in WHERE: doctors above average patient load
SELECT 
  CONCAT(doc.first_name, ' ', doc.last_name) AS doctor_name,
  doc.speciality,
  COUNT(a.admission_id) AS patients_treated
FROM doctors doc
JOIN admissions a ON doc.doctor_id = a.doctor_id
GROUP BY doc.doctor_id, doc.first_name, doc.last_name, doc.speciality
HAVING COUNT(a.admission_id) > (
  SELECT AVG(patient_count)
  FROM (
    SELECT COUNT(admission_id) AS patient_count
    FROM admissions
    GROUP BY doctor_id
  ) AS dept_counts
)
ORDER BY patients_treated DESC;

-- Subquery in FROM: department billing summary
SELECT 
  dept_summary.dept_name,
  dept_summary.total_patients,
  dept_summary.avg_bill,
  dept_summary.total_revenue
FROM (
  SELECT 
    dep.dept_name,
    COUNT(a.admission_id)    AS total_patients,
    AVG(b.total_amount)      AS avg_bill,
    SUM(b.total_amount)      AS total_revenue
  FROM departments dep
  JOIN admissions a ON dep.dept_id    = a.dept_id
  JOIN billing b    ON a.admission_id = b.admission_id
  GROUP BY dep.dept_id, dep.dept_name
) AS dept_summary
ORDER BY dept_summary.total_revenue DESC;

-- Subquery in FROM: patient risk classification
SELECT 
  risk_group,
  COUNT(*)   AS total_patients,
  AVG(age)   AS avg_age,
  MIN(age)   AS youngest,
  MAX(age)   AS oldest
FROM (
  SELECT 
    CONCAT(first_name, ' ', last_name) AS patient_name,
    TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) AS age,
    CASE
      WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 18 THEN 'Pediatric'
      WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 40 THEN 'Young Adult'
      WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 65 THEN 'Middle Aged'
      ELSE 'Elderly'
    END AS risk_group
  FROM patients
) AS classified_patients
GROUP BY risk_group
ORDER BY avg_age DESC;

-- Subquery in SELECT: each patient bill vs hospital average
SELECT 
  CONCAT(p.first_name, ' ', p.last_name)  AS patient_name,
  d.diagnosis,
  b.total_amount                           AS patient_bill,
  (SELECT AVG(total_amount) FROM billing)  AS hospital_avg,
  b.total_amount - 
  (SELECT AVG(total_amount) FROM billing)  AS difference_from_avg
FROM patients p
JOIN admissions a ON p.patient_id   = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
JOIN billing b    ON a.admission_id = b.admission_id
ORDER BY difference_from_avg DESC;

-- EXISTS: patients who received medication
SELECT 
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  d.diagnosis
FROM patients p
JOIN admissions a ON p.patient_id   = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
WHERE EXISTS (
  SELECT 1 
  FROM medications m 
  WHERE m.admission_id = a.admission_id
);

-- NOT EXISTS: patients with NO medication prescribed
SELECT 
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  d.diagnosis,
  d.severity
FROM patients p
JOIN admissions a ON p.patient_id   = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
WHERE NOT EXISTS (
  SELECT 1 
  FROM medications m 
  WHERE m.admission_id = a.admission_id
);