-- 1. Add Auto Monthly Payroll Settings columns
ALTER TABLE atk_settings ADD COLUMN IF NOT EXISTS auto_monthly_payroll_enabled TINYINT(1) DEFAULT 0;
ALTER TABLE atk_settings ADD COLUMN IF NOT EXISTS last_auto_closing_month VARCHAR(7) NULL;

-- 2. Clean up any existing historical duplicate rows in atk_monthly_payrolls before creating UNIQUE index
DELETE t1 FROM atk_monthly_payrolls t1
INNER JOIN atk_monthly_payrolls t2 
WHERE t1.id > t2.id 
  AND t1.employee_id = t2.employee_id 
  AND t1.end_date = t2.end_date;

-- 3. Add UNIQUE KEY constraint to prevent any future duplicates
ALTER TABLE atk_monthly_payrolls ADD UNIQUE KEY unique_emp_end_date (employee_id, end_date);
