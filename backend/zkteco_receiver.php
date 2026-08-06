<?php
/**
 * ZKTeco Fingerprint Log Receiver
 * This script receives events from the device, logs them to a JSONL file,
 * and can be extended to sync directly with the MySQL database.
 */

// 1. Initial Data Capture
$raw = file_get_contents("php://input");
$contentType = $_SERVER['CONTENT_TYPE'] ?? $_SERVER['HTTP_CONTENT_TYPE'] ?? '';

$post = $_POST;
if (empty($post) && stripos($contentType, 'application/x-www-form-urlencoded') !== false && is_string($raw)) {
    parse_str($raw, $post);
}

/**
 * Converts device date format to standard ISO
 */
function toIsoDatetime(?string $s): ?string {
    if (!$s) return null;
    $dt = DateTime::createFromFormat('d/m/Y H:i:s', $s);
    return $dt ? $dt->format(DateTime::ATOM) : null;
}

// 2. Process Raw Events
$events = [];
foreach ($post as $k => $v) {
    if (is_array($v)) continue;

    $decoded = json_decode($v, true);
    if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
        $userId = isset($decoded["user_id"]) ? (int)$decoded["user_id"] : null;
        $dtRaw  = $decoded["events_datetime"] ?? null;
        $dtIso  = toIsoDatetime($dtRaw);

        $events[] = [
            "user_id" => $userId,
            "datetime" => $dtRaw,
            "datetime_iso" => $dtIso,
            "seq" => is_numeric($k) ? (int)$k : $k,
        ];
    }
}

// 3. Sort Events by Time
usort($events, function($a, $b) {
    $ai = $a["datetime_iso"] ?? "";
    $bi = $b["datetime_iso"] ?? "";
    if ($ai === $bi) return ($a["seq"] ?? 0) <=> ($b["seq"] ?? 0);
    return strcmp($ai, $bi);
});

// 4. Group by User and Date (Summary for the batch)
$userDays = [];
foreach ($events as $e) {
    if (!$e["user_id"] || !$e["datetime_iso"]) continue;
    
    $uid = (string)$e["user_id"];
    $date = date('Y-m-d', strtotime($e["datetime_iso"]));
    $key = $uid . "_" . $date;

    if (!isset($userDays[$key])) {
        $userDays[$key] = [
            "user_id" => $uid,
            "date" => $date,
            "count" => 0,
            "first" => null,
            "last" => null,
            "events" => [],
        ];
    }

    $userDays[$key]["count"] += 1;
    $userDays[$key]["events"][] = [
        "datetime" => $e["datetime"],
        "datetime_iso" => $e["datetime_iso"],
    ];

    $iso = $e["datetime_iso"];
    if ($userDays[$key]["first"] === null || $iso < $userDays[$key]["first"]) $userDays[$key]["first"] = $iso;
    if ($userDays[$key]["last"]  === null || $iso > $userDays[$key]["last"])  $userDays[$key]["last"]  = $iso;
}

uksort($userDays, fn($a,$b) => strcmp($a, $b));

// 5. Build Log Object
$log = [
    "time" => date("c"),
    "ip" => $_SERVER["REMOTE_ADDR"] ?? null,
    "events_count" => count($events),
    "user_days_count" => count($userDays),
    "user_days" => $userDays, // Replaced 'users' with 'user_days' for clarity
    "events" => array_map(function($e){
        unset($e["seq"]);
        return $e;
    }, $events),
];

// 6. Save to Log File
file_put_contents(
    __DIR__ . "/database/atten.jsonl",
    json_encode($log, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) . "\n", // One line for true JSONL
    FILE_APPEND
);

// Database Sync Logic...
require_once 'database/db.php';
require_once 'models/Attendance.php';
require_once 'models/Setting.php';
require_once 'models/Employee.php';
require_once 'models/AttendanceCalculator.php';

$database = new Database();
$db = $database->getConnection();
$setting = new Setting($db);
$employeeModule = new Employee($db);

$settings = $setting->getSettings();
$default_start = $settings['default_start_time'] ?? '08:00:00';
$allowed_late = $settings['allowed_late_minutes'] ?? 15;
$default_end = $settings['default_end_time'] ?? '16:00:00';
if (isset($settings['ramadan_mode']) && $settings['ramadan_mode'] == 1) {
    $default_start = $settings['ramadan_start_time'] ?? '10:00:00';
    $default_end = $settings['ramadan_end_time'] ?? '15:00:00';
}

// Optimization: Cache employees
$allEmps = [];
$stEmp = $db->prepare("SELECT id, special_start_time, special_end_time, is_flexible, required_hours FROM atk_employees");
$stEmp->execute();
while($row = $stEmp->fetch(PDO::FETCH_ASSOC)) $allEmps[$row['id']] = $row;

$db->beginTransaction();
try {
    foreach ($userDays as $key => $record) {
        $empId = $record['user_id'];
        if (!isset($allEmps[$empId])) continue;

        $empInfo = $allEmps[$empId];
        $date = $record['date'];
        $checkIn = date('Y-m-d H:i:s', strtotime($record['first']));
        $checkOut = $record['count'] > 1 ? date('Y-m-d H:i:s', strtotime($record['last'])) : null;

        $calc = AttendanceCalculator::calculate($checkIn, $checkOut, $date, $empInfo, $settings);
        
        $late_minutes = $calc['late_minutes'];
        $early_exit_minutes = $calc['early_exit_minutes'];
        $status = $calc['status'];

        $query = "INSERT INTO atk_attendance 
                  (employee_id, date, check_in, check_out, late_minutes, early_exit_minutes, status, source) 
                  VALUES (:emp_id, :b_date, :check_in, :check_out, :late, :early, :status, :source)
                  ON DUPLICATE KEY UPDATE 
                  check_out = VALUES(check_out),
                  status = VALUES(status),
                  late_minutes = VALUES(late_minutes),
                  early_exit_minutes = VALUES(early_exit_minutes)";

        $stmt = $db->prepare($query);
        $stmt->execute([
            ":emp_id"   => $empId,
            ":b_date"   => $date,
            ":check_in" => $checkIn,
            ":check_out"=> $checkOut,
            ":late"     => $late_minutes,
            ":early"    => $early_exit_minutes,
            ":status"   => $status,
            ":source"   => 'device_sync'
        ]);
    }
    $db->commit();
} catch (Exception $e) {
    $db->rollBack();
}

http_response_code(200);
echo "OK";
