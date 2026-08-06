<?php
require_once 'c:\\xampp\\htdocs\\attendace\\backend\\database\\db.php';
require_once 'c:\\xampp\\htdocs\\attendace\\backend\\services\\AttendanceEngine.php';

$database = new Database();
$db = $database->getConnection();
$engine = new AttendanceEngine($db);

$summary = $engine->getMonthlySummary(123, 6, 2026);

// just find late days
foreach ($summary['days'] as $day) {
    if ($day['late_discount'] > 0 || $day['early_exit_discount'] > 0 || $day['late_minutes'] > 0) {
        echo "Date: " . $day['date'] . " | Late Mins: " . $day['late_minutes'] . " | Late Disc: " . $day['late_discount'] . " | Early Mins: " . $day['early_exit_minutes'] . " | Early Disc: " . $day['early_exit_discount'] . "\n";
    }
}
