<?php
require_once 'backend/database/db.php';
require_once 'backend/models/AttendanceCalculator.php';

$database = new Database();
$db = $database->getConnection();

// Fetch settings
$stmt = $db->query("SELECT * FROM atk_settings ORDER BY id DESC LIMIT 1");
$settings = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$settings) {
    $settings = [
        'default_start_time' => '08:00:00',
        'default_end_time' => '16:00:00',
        'ramadan_mode' => 0
    ];
}

// Fetch employees
$stmt = $db->query("SELECT id, name, vacation_credit, special_start_time, special_end_time FROM atk_employees");
$employees = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "| Employee Name | ID | Minutes | Hours | Days |\n";
echo "| ------------- | -- | ------- | ----- | ---- |\n";

foreach ($employees as $emp) {
    $minutes = $emp['vacation_credit'] ?? 0;
    
    // Format hours (always rounded down, or exact 1 decimal)
    $hours = $minutes / 60;
    $hoursStr = number_format($hours, 1);
    
    // Calculate Work Day Duration
    $workDayMinutes = AttendanceCalculator::getWorkDayDuration($emp, $settings);
    if ($workDayMinutes <= 0) $workDayMinutes = 480; // Safety fallback
    
    // Format Days
    $days = $minutes / $workDayMinutes;
    // Format to 1 decimal place and remove trailing .0
    $daysStr = number_format($days, 1);
    $daysStr = preg_replace('/\.0$/', '', $daysStr);
    
    echo "| " . $emp['name'] . " | " . $emp['id'] . " | " . $minutes . " | " . $hoursStr . " | " . $daysStr . " |\n";
}
