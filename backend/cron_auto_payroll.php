<?php
/**
 * Cron / Scheduled Task Script for ProAttend Auto Monthly Payroll Closing
 * Usage:
 *   - Command line / Task Scheduler: C:\xampp\php\php.exe c:\xampp\htdocs\attendace\backend\cron_auto_payroll.php
 *   - Web / API request: GET /backend/cron_auto_payroll.php
 */

header("Content-Type: application/json; charset=UTF-8");
require_once __DIR__ . '/database/db.php';
require_once __DIR__ . '/models/Setting.php';
require_once __DIR__ . '/services/AttendanceEngine.php';

try {
    $database = new Database();
    $db = $database->getConnection();

    $engine = new AttendanceEngine($db);
    $result = $engine->autoRunMonthlyPayrollClosingForAll();

    echo json_encode([
        "timestamp" => date("Y-m-d H:i:s"),
        "result" => $result
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
