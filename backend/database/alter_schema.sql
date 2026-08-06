-- 1. Updates for Employees Table (Flexible Work Support)
ALTER TABLE atk_employees 
ADD COLUMN IF NOT EXISTS is_flexible BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS required_hours DECIMAL(4,2) DEFAULT 8.00;

-- 2. Updates for Attendance Table (Early Exit Support)
ALTER TABLE atk_attendance 
ADD COLUMN IF NOT EXISTS early_exit_minutes INT DEFAULT 0,
MODIFY COLUMN status ENUM('present', 'late', 'absent', 'incomplete', 'holiday', 'vacation', 'early_exit') NOT NULL;

-- 3. Updates for Vacations Table (Hourly Vacation & Detailed Metadata)
ALTER TABLE atk_vacations 
ADD COLUMN IF NOT EXISTS attachment VARCHAR(255) NULL,
ADD COLUMN IF NOT EXISTS reason TEXT NULL,
ADD COLUMN IF NOT EXISTS is_hourly BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS start_time TIME NULL,
ADD COLUMN IF NOT EXISTS end_time TIME NULL,
ADD COLUMN IF NOT EXISTS total_minutes INT DEFAULT 0;

-- 4. Updates for Holidays Table (Multi-day & Recurring Holidays)
ALTER TABLE atk_holidays
ADD COLUMN IF NOT EXISTS end_date DATE NULL,
ADD COLUMN IF NOT EXISTS is_recurring BOOLEAN DEFAULT FALSE;

-- 5. Updates for Settings Table (Automatic App Update Support)
ALTER TABLE atk_settings
ADD COLUMN IF NOT EXISTS min_version INT DEFAULT 1,
ADD COLUMN IF NOT EXISTS force_update_url VARCHAR(500) NULL;

-- 6. Cleanup: Remove Deprecated Objections System
DROP TABLE IF EXISTS atk_objections;
