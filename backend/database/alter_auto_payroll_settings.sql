-- Alter atk_settings table to support automatic monthly payroll closings
ALTER TABLE atk_settings ADD COLUMN IF NOT EXISTS auto_monthly_payroll_enabled TINYINT(1) DEFAULT 0;
ALTER TABLE atk_settings ADD COLUMN IF NOT EXISTS last_auto_closing_month VARCHAR(7) NULL;
