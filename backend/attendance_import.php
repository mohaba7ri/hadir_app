<?php
require_once 'database/db.php';
require_once 'models/Employee.php';
require_once 'models/Attendance.php';
require_once 'models/Setting.php';

// This script can be called from CLI: php attendance_import.php file.json
if ($argc < 2) {
    die("Usage: php attendance_import.php <filename.json>\n");
}

$filename = $argv[1];
if (!file_exists($filename)) {
    die("File not found: $filename\n");
}

$jsonData = file_get_contents($filename);
$data = json_decode($jsonData, true);

if (!$data || !isset($data['users'])) {
    die("Invalid JSON format.\n");
}

$database = new Database();
$db = $database->getConnection();

$attendance = new Attendance($db);
$setting = new Setting($db);
$employee = new Employee($db);

$settings = $setting->getSettings();
$default_start = $settings['default_start_time'] ?? '08:00:00';
$allowed_late = $settings['allowed_late_minutes'] ?? 15;

if (isset($settings['ramadan_mode']) && $settings['ramadan_mode'] == 1) {
    $default_start = $settings['ramadan_start_time'] ?? '10:00:00';
}

$imported = 0;
foreach ($data['users'] as $empId => $record) {
    $empInfo = $employee->readOne($empId);
    if (!$empInfo) continue;

    $work_start = $empInfo['special_start_time'] ?? $default_start;
    $firstIso = $record['first'];
    $lastIso = $record['last'];
    $date = date('Y-m-d', strtotime($firstIso));
    $checkIn = date('Y-m-d H:i:s', strtotime($firstIso));
    $checkOut = count($record['events']) > 1 ? date('Y-m-d H:i:s', strtotime($lastIso)) : null;

    $late_minutes = 0;
    $expected = date('Y-m-d H:i:s', strtotime($date . ' ' . $work_start));
    if (strtotime($checkIn) > strtotime($expected)) {
        $late_minutes = floor((strtotime($checkIn) - strtotime($expected)) / 60);
    }

    $status = 'present';
    if ($late_minutes > $allowed_late) $status = 'late';
    if (!$checkOut) $status = 'incomplete';

    $attendance->employee_id = $empId;
    $attendance->date = $date;
    $attendance->check_in = $checkIn;
    $attendance->check_out = $checkOut;
    $attendance->late_minutes = $late_minutes;
    $attendance->status = $status;
    $attendance->source = 'cli_import';

    if ($attendance->create()) {
        $imported++;
        echo "Imported: Employee $empId on $date\n";
    } else {
        echo "Skipped (Duplicate): Employee $empId on $date\n";
    }
}
echo "Done. Total imported: $imported\n";
?>
