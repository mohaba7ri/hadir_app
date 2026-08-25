-- Migration Script: Add Auto Monthly Payroll Closing Settings & Duplicate Protection Index
ALTER TABLE atk_settings ADD COLUMN IF NOT EXISTS auto_monthly_payroll_enabled TINYINT(1) DEFAULT 0;
ALTER TABLE atk_settings ADD COLUMN IF NOT EXISTS last_auto_closing_month VARCHAR(7) NULL;

-- Guarantee 100% duplicate protection for monthly payroll records
ALTER TABLE atk_monthly_payrolls ADD UNIQUE KEY IF NOT EXISTS unique_emp_end_date (employee_id, end_date);
