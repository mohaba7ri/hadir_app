<?php
require_once 'database/db.php';
require_once 'models/Setting.php';

$database = new Database();
$db = $database->getConnection();

// 1. Alter Employee Table
try {
    $db->exec("ALTER TABLE atk_employees MODIFY COLUMN vacation_credit DECIMAL(10,2) DEFAULT 0");
    echo "Employee table modified.\n";
} catch (Exception $e) {
    echo "Error modifying employee table: " . $e->getMessage() . "\n";
}

// 2. Alter Vacations Table
try {
    $db->exec("ALTER TABLE atk_vacations ADD COLUMN is_hourly BOOLEAN DEFAULT FALSE");
    $db->exec("ALTER TABLE atk_vacations ADD COLUMN start_time TIME NULL");
    $db->exec("ALTER TABLE atk_vacations ADD COLUMN end_time TIME NULL");
    $db->exec("ALTER TABLE atk_vacations ADD COLUMN total_minutes INT DEFAULT 0");
    echo "Vacations table modified.\n";
} catch (Exception $e) {
    echo "Error modifying vacations table: " . $e->getMessage() . "\n";
}

// 3. Convert existing credits and vacation records
// We'll treat current 'vacation_credit' as days and convert to minutes.
$settingModel = new Setting($db);
$settings = $settingModel->getSettings();

function parseTime($time) {
    return strtotime("2000-01-01 $time");
}

$defaultDuration = 8 * 60; // fallback
if ($settings) {
    $start = parseTime($settings['default_start_time']);
    $end = parseTime($settings['default_end_time']);
    $defaultDuration = ($end - $start) / 60;
}

// Update employees
$stmt = $db->query("SELECT * FROM atk_employees");
while ($emp = $stmt->fetch(PDO::FETCH_ASSOC)) {
    $duration = $defaultDuration;
    
    if ($emp['is_flexible'] && $emp['required_hours'] > 0) {
        $duration = $emp['required_hours'] * 60;
    } else if ($emp['special_start_time'] && $emp['special_end_time']) {
        $s = parseTime($emp['special_start_time']);
        $e = parseTime($emp['special_end_time']);
        $duration = ($e - $s) / 60;
    }
    
    // Convert current 'days' to minutes
    // If it's already a large number (like > 365), assume it's already minutes? 
    // No, usually it's around 30.
    if ($emp['vacation_credit'] < 100) { 
        $minutes = $emp['vacation_credit'] * $duration;
        $id = $emp['id'];
        $db->exec("UPDATE atk_employees SET vacation_credit = $minutes WHERE id = $id");
    }
}

// Update existing vacations
$db->exec("UPDATE atk_vacations SET total_minutes = total_days * 8 * 60 WHERE is_hourly = FALSE");

echo "Migration completed successfully.\n";
?>
