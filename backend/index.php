<?php
ob_start();
// backend/index.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Global Error Handler to ensure JSON response
error_reporting(E_ALL);
ini_set('display_errors', 0);

set_exception_handler(function ($e) {
    if (ob_get_length())
        ob_clean();
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "خطأ داخلي في الخادم",
        "debug" => $e->getMessage()
    ]);
    exit();
});

set_error_handler(function ($errno, $errstr, $errfile, $errline) {
    if (!(error_reporting() & $errno))
        return;
    if (ob_get_length())
        ob_clean();
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "خطأ PHP: $errstr في $errfile على السطر $errline"
    ]);
    exit();
});

$request_uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$path_parts = explode('/', trim($request_uri, '/'));

// Find 'backend' in the path to determine where our endpoints start
$base_index = array_search('backend', $path_parts);

if ($base_index === false || !isset($path_parts[$base_index + 1])) {
    echo json_encode(["status" => "success", "message" => "واجهة برمجة تطبيقات نظام الحضور تعمل بنجاح."]);
    exit();
}

$resource = $path_parts[$base_index + 1];
$id = isset($path_parts[$base_index + 2]) ? $path_parts[$base_index + 2] : null;

require_once 'database/db.php';

$database = new Database();
$db = $database->getConnection();

// Lightweight background auto-check for monthly payroll closings
try {
    require_once __DIR__ . '/models/Setting.php';
    require_once __DIR__ . '/services/AttendanceEngine.php';
    $autoEngine = new AttendanceEngine($db);
    $autoEngine->autoRunMonthlyPayrollClosingForAll();
} catch (Throwable $t) {
    // Non-blocking
}

$routes = [
    'employees' => 'routes/employees_route.php',
    'attendance' => 'routes/attendance_route.php',
    'vacations' => 'routes/vacation_route.php',
    'settings' => 'routes/settings_route.php',
    'holidays' => 'routes/holidays_route.php',
    'reports' => 'routes/reports_route.php',
    'auth' => 'routes/auth_route.php',
    'departments' => 'routes/department_route.php',
    'overtime' => 'routes/overtime_route.php',
    'attendance-corrections' => 'routes/attendance_corrections_route.php',
    'setup_db_now' => 'setup_db.php',
    'list_tables' => 'list_tables.php',
];

if (array_key_exists($resource, $routes)) {
    require_once $routes[$resource];
} else {
    http_response_code(404);
    echo json_encode(["message" => "المسار غير موجود"]);
}
?>