-- =============================================
-- DAY 12: Indexes, Views, Transactions & Design
-- Dataset: City General Hospital (hospital_db)
-- =============================================

-- EXPLAIN: check query execution before index
EXPLAIN SELECT * FROM patients WHERE city = 'Lagos';

-- Create index on city column
CREATE INDEX idx_patients_city ON patients(city);

-- EXPLAIN: check query execution after index
EXPLAIN SELECT * FROM patients WHERE city = 'Lagos';

-- Create indexes on frequently queried columns
CREATE INDEX idx_admissions_date         ON admissions(admission_date);
CREATE INDEX idx_admissions_patient      ON admissions(patient_id);
CREATE INDEX idx_admissions_doctor       ON admissions(doctor_id);
CREATE INDEX idx_diagnoses_severity      ON diagnoses(severity);
CREATE INDEX idx_billing_status          ON billing(payment_status);
CREATE INDEX idx_admissions_patient_date ON admissions(patient_id, admission_date);

-- View all indexes on admissions table
SHOW INDEXES FROM admissions;

-- Create comprehensive patient admission view
CREATE VIEW vw_patient_admission_summary AS
SELECT 
  CONCAT(p.first_name, ' ', p.last_name)          AS patient_name,
  TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE())  AS age,
  p.gender,
  p.blood_type,
  dep.dept_name,
  CONCAT(doc.first_name, ' ', doc.last_name)       AS doctor_name,
  doc.speciality,
  a.admission_type,
  DATE_FORMAT(a.admission_date, '%M %d, %Y')       AS admission_date,
  DATEDIFF(
    COALESCE(a.discharge_date, CURDATE()),
    a.admission_date
  )                                                 AS length_of_stay,
  d.diagnosis,
  d.severity,
  b.total_amount,
  b.payment_status
FROM patients p
JOIN admissions a    ON p.patient_id   = a.patient_id
JOIN doctors doc     ON a.doctor_id    = doc.doctor_id
JOIN departments dep ON a.dept_id      = dep.dept_id
JOIN diagnoses d     ON a.admission_id = d.admission_id
JOIN billing b       ON a.admission_id = b.admission_id;

-- Query the view
SELECT * FROM vw_patient_admission_summary;

-- Query view for critical patients only
SELECT * FROM vw_patient_admission_summary
WHERE severity = 'Critical';

-- Query view for unpaid bills
SELECT patient_name, diagnosis, total_amount, payment_status
FROM vw_patient_admission_summary
WHERE payment_status IN ('Pending', 'Partial')
ORDER BY total_amount DESC;

-- Query view for Cardiology department
SELECT patient_name, doctor_name, diagnosis, length_of_stay
FROM vw_patient_admission_summary
WHERE dept_name = 'Cardiology';

-- Transaction: patient discharge process
SET autocommit = 0;

START TRANSACTION;

UPDATE admissions 
SET discharge_date = '2024-06-20'
WHERE admission_id = 2;

UPDATE billing
SET payment_status = 'Pending'
WHERE admission_id = 2;

COMMIT;

-- Verify transaction committed
SELECT 
  a.admission_id,
  a.discharge_date,
  b.payment_status
FROM admissions a
JOIN billing b ON a.admission_id = b.admission_id
WHERE a.admission_id = 2;