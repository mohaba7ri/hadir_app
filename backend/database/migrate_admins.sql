-- Create Admin Table
CREATE TABLE IF NOT EXISTS atk_admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255) DEFAULT '',
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'super_admin') DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert Default Administrators
INSERT INTO atk_admins (username, password, role, full_name) VALUES 
('admin', '123', 'admin', 'المدير العام'),
('super_admin', 'admin', 'super_admin', 'المسؤول المتميز'),
('moha', '730010012', 'admin', 'المهندس محمد')
ON DUPLICATE KEY UPDATE password = VALUES(password), role = VALUES(role), full_name = VALUES(full_name);
