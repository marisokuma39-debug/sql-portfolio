-- =============================================
-- DAY 10: Window Functions
-- Dataset: City General Hospital (hospital_db)
-- =============================================

-- ROW_NUMBER, RANK, DENSE_RANK comparison
SELECT 
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  d.diagnosis,
  b.total_amount,
  ROW_NUMBER()  OVER (ORDER BY b.total_amount DESC) AS row_num,
  RANK()        OVER (ORDER BY b.total_amount DESC) AS rank_pos,
  DENSE_RANK()  OVER (ORDER BY b.total_amount DESC) AS dense_rank_pos
FROM patients p
JOIN admissions a ON p.patient_id   = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
JOIN billing b    ON a.admission_id = b.admission_id
ORDER BY b.total_amount DESC;

-- PARTITION BY: rank patients within each department
SELECT 
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  dep.dept_name,
  b.total_amount,
  RANK() OVER (
    PARTITION BY a.dept_id 
    ORDER BY b.total_amount DESC
  ) AS dept_rank
FROM patients p
JOIN admissions a    ON p.patient_id   = a.patient_id
JOIN billing b       ON a.admission_id = b.admission_id
JOIN departments dep ON a.dept_id      = dep.dept_id
WHERE dep.dept_name = 'Cardiology'
ORDER BY dept_rank ASC;

-- Top billing patient per department
SELECT * FROM (
  SELECT 
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    dep.dept_name,
    d.diagnosis,
    b.total_amount,
    RANK() OVER (
      PARTITION BY a.dept_id 
      ORDER BY b.total_amount DESC
    ) AS dept_rank
  FROM patients p
  JOIN admissions a    ON p.patient_id   = a.patient_id
  JOIN billing b       ON a.admission_id = b.admission_id
  JOIN diagnoses d     ON a.admission_id = d.admission_id
  JOIN departments dep ON a.dept_id      = dep.dept_id
) ranked
WHERE dept_rank = 1
ORDER BY total_amount DESC;

-- LAG: monthly admissions trend
SELECT 
  DATE_FORMAT(admission_date, '%Y-%m')  AS month,
  COUNT(*)                               AS total_admissions,
  LAG(COUNT(*)) OVER (
    ORDER BY DATE_FORMAT(admission_date, '%Y-%m')
  )                                      AS prev_month_admissions,
  COUNT(*) - LAG(COUNT(*)) OVER (
    ORDER BY DATE_FORMAT(admission_date, '%Y-%m')
  )                                      AS month_change
FROM admissions
GROUP BY DATE_FORMAT(admission_date, '%Y-%m')
ORDER BY month;

-- LAG: monthly billing revenue trend
SELECT 
  DATE_FORMAT(a.admission_date, '%Y-%m')   AS month,
  SUM(b.total_amount)                       AS monthly_revenue,
  LAG(SUM(b.total_amount)) OVER (
    ORDER BY DATE_FORMAT(a.admission_date, '%Y-%m')
  )                                          AS prev_month_revenue,
  SUM(b.total_amount) - 
  LAG(SUM(b.total_amount)) OVER (
    ORDER BY DATE_FORMAT(a.admission_date, '%Y-%m')
  )                                          AS revenue_change
FROM admissions a
JOIN billing b ON a.admission_id = b.admission_id
GROUP BY DATE_FORMAT(a.admission_date, '%Y-%m')
ORDER BY month;

-- SUM OVER: cumulative revenue
SELECT 
  DATE_FORMAT(a.admission_date, '%Y-%m')  AS month,
  SUM(b.total_amount)                      AS monthly_revenue,
  SUM(SUM(b.total_amount)) OVER (
    ORDER BY DATE_FORMAT(a.admission_date, '%Y-%m')
  )                                         AS cumulative_revenue
FROM admissions a
JOIN billing b ON a.admission_id = b.admission_id
GROUP BY DATE_FORMAT(a.admission_date, '%Y-%m')
ORDER BY month;

-- AVG OVER: 3 month moving average
SELECT 
  DATE_FORMAT(a.admission_date, '%Y-%m')  AS month,
  SUM(b.total_amount)                      AS monthly_revenue,
  ROUND(
    AVG(SUM(b.total_amount)) OVER (
      ORDER BY DATE_FORMAT(a.admission_date, '%Y-%m')
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2
  )                                         AS moving_avg_3month
FROM admissions a
JOIN billing b ON a.admission_id = b.admission_id
GROUP BY DATE_FORMAT(a.admission_date, '%Y-%m')
ORDER BY month;

-- NTILE: patient billing quartiles
SELECT 
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  d.diagnosis,
  b.total_amount,
  NTILE(4) OVER (
    ORDER BY b.total_amount DESC
  )                                        AS billing_quartile
FROM patients p
JOIN admissions a ON p.patient_id   = a.patient_id
JOIN diagnoses d  ON a.admission_id = d.admission_id
JOIN billing b    ON a.admission_id = b.admission_id
ORDER BY billing_quartile, b.total_amount DESC;