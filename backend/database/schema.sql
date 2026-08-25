CREATE TABLE IF NOT EXISTS atk_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    default_start_time TIME DEFAULT '08:00:00',
    allowed_late_minutes INT DEFAULT 15,
    ramadan_start_time TIME DEFAULT '10:00:00',
    ramadan_end_time TIME DEFAULT '15:00:00',
    ramadan_mode BOOLEAN DEFAULT FALSE,
    default_end_time TIME DEFAULT '16:00:00',
    last_renewal_year INT DEFAULT 2026,
    min_version INT DEFAULT 1,
    force_update_url VARCHAR(500) NULL,
    auto_monthly_payroll_enabled TINYINT(1) DEFAULT 0,
    last_auto_closing_month VARCHAR(7) NULL
);

INSERT INTO atk_settings (default_start_time, allowed_late_minutes, ramadan_start_time, ramadan_end_time, ramadan_mode, default_end_time)
SELECT '08:00:00', 15, '10:00:00', '15:00:00', 0, '16:00:00'
FROM DUAL WHERE NOT EXISTS (SELECT * FROM atk_settings);

CREATE TABLE IF NOT EXISTS atk_employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    position VARCHAR(255),
    salary DECIMAL(10,2) DEFAULT 0.00,
    special_start_time TIME NULL,
    special_end_time TIME NULL,
    vacation_credit INT DEFAULT 14400, -- 30 days * 8 hours * 60 mins = 14400 minutes
    work_days_per_week INT DEFAULT 6,
    is_flexible BOOLEAN DEFAULT FALSE,
    required_hours DECIMAL(4,2) DEFAULT 8.00,
    status ENUM('active', 'inactive') DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS atk_attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    date DATE NOT NULL,
    check_in DATETIME NULL,
    check_out DATETIME NULL,
    late_minutes INT DEFAULT 0,
    early_exit_minutes INT DEFAULT 0,
    status ENUM('present', 'late', 'absent', 'incomplete', 'holiday', 'vacation', 'early_exit') NOT NULL,
    source VARCHAR(50) DEFAULT 'json_import',
    UNIQUE KEY unique_employee_date (employee_id, date),
    FOREIGN KEY (employee_id) REFERENCES atk_employees(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS atk_holidays (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    end_date DATE NULL,
    is_recurring BOOLEAN DEFAULT FALSE,
    UNIQUE KEY unique_holiday_date (date)
);

CREATE TABLE IF NOT EXISTS atk_weekly_holidays (
    id INT AUTO_INCREMENT PRIMARY KEY,
    day_name ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL
);

INSERT INTO atk_weekly_holidays (day_name)
SELECT 'Friday' FROM DUAL WHERE NOT EXISTS (SELECT * FROM atk_weekly_holidays WHERE day_name = 'Friday');
INSERT INTO atk_weekly_holidays (day_name)
SELECT 'Saturday' FROM DUAL WHERE NOT EXISTS (SELECT * FROM atk_weekly_holidays WHERE day_name = 'Saturday');

CREATE TABLE IF NOT EXISTS atk_vacations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days INT NOT NULL,
    vacation_type VARCHAR(255) DEFAULT 'إجازة سنوية',
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    attachment VARCHAR(255) NULL,
    reason TEXT NULL,
    is_hourly BOOLEAN DEFAULT FALSE,
    start_time TIME NULL,
    end_time TIME NULL,
    total_minutes INT DEFAULT 0,
    FOREIGN KEY (employee_id) REFERENCES atk_employees(id) ON DELETE CASCADE
);
