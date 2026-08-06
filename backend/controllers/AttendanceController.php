<?php
require_once __DIR__ . '/../models/Attendance.php';
require_once __DIR__ . '/../models/Setting.php';
require_once __DIR__ . '/../models/Employee.php';
require_once __DIR__ . '/../models/AttendanceCalculator.php';
require_once __DIR__ . '/../services/AttendanceEngine.php';

class AttendanceController
{
    private $db;
    private $attendance;
    private $setting;
    private $employee;

    public function __construct($db)
    {
        $this->db = $db;
        $this->attendance = new Attendance($db);
        $this->setting = new Setting($db);
        $this->employee = new Employee($db);
    }

    public function processRequest($method, $id, $action)
    {
        if ($method === 'GET') {
            if ($action === 'monthly-summary') {
                $employee_id = $_GET['employee_id'] ?? null;
                $month = $_GET['month'] ?? date('m');
                $year = $_GET['year'] ?? date('Y');

                if (!$employee_id) {
                    http_response_code(400);
                    echo json_encode(["message" => "Employee ID is required."]);
                    return;
                }

                try {
                    $engine = new AttendanceEngine($this->db);
                    $result = $engine->getMonthlySummary($employee_id, $month, $year);
                    echo json_encode($result);
                } catch (Exception $e) {
                    http_response_code(500);
                    echo json_encode(["message" => $e->getMessage()]);
                }
                return;
            }

            $settings = $this->setting->getSettings();
            $stmt = $this->attendance->readAll();
            $data = [];
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $workDuration = AttendanceCalculator::getWorkDayDuration($row, $settings);
                $divisor = (isset($row['work_days_per_week']) && $row['work_days_per_week'] == 7) ? date('t', strtotime($row['date'])) : 26;

                // ON THE FLY CALCULATION
                $calc = AttendanceCalculator::calculate($row['check_in'], $row['check_out'], $row['date'], $row, $settings);
                $row['late_minutes'] = $calc['late_minutes'];
                $row['early_exit_minutes'] = $calc['early_exit_minutes'];
                $row['status'] = $calc['status'];

                $late = (int) $row['late_minutes'];
                $early = (int) $row['early_exit_minutes'];
                $hourlyLate = (int) ($row['approved_hourly_late'] ?? 0);
                $hourlyEarly = (int) ($row['approved_hourly_early'] ?? 0);
                $hourlyBoth = (int) ($row['approved_hourly_both'] ?? 0);

                // Subtract specific approved hourly vacation minutes from penalties
                $effectiveLate = max(0, $late - $hourlyLate);
                $effectiveEarly = max(0, $early - $hourlyEarly);

                // Subtract generic approved hourly vacation minutes from penalties (Late first, then Early)
                $hb_used_for_late = min($hourlyBoth, $effectiveLate);
                $effectiveLate = max(0, $effectiveLate - $hb_used_for_late);
                $hbRemaining = max(0, $hourlyBoth - $hb_used_for_late);

                $effectiveEarly = max(0, $effectiveEarly - $hbRemaining);

                // Update row with effective minutes so the frontend doesn't need to recalculate them!
                $row['late_minutes'] = $effectiveLate;
                $row['early_exit_minutes'] = $effectiveEarly;

                $row['late_discount'] = AttendanceCalculator::calculateDiscount(
                    (float) $row['salary'],
                    $effectiveLate,
                    0,
                    $workDuration,
                    $divisor
                );

                $row['early_exit_discount'] = AttendanceCalculator::calculateDiscount(
                    (float) $row['salary'],
                    0,
                    $effectiveEarly,
                    $workDuration,
                    $divisor
                );

                $row['discount'] = $row['late_discount'] + $row['early_exit_discount'];

                // For absent records, calculate total daily discount if not already set
                if ($row['status'] == 'absent') {
                    $row['discount'] = (float) $row['salary'] / $divisor;
                }

                $data[] = $row;
            }
            echo json_encode($data);
        } else if ($method === 'POST') {
            if ($action === 'import') {
                $this->importJson();
            } else if ($action === 'sync_file') {
                $this->syncFromFile();
            } else if ($action === 'update_note') {
                $this->updateNote();
            } else {
                http_response_code(400);
                echo json_encode(["message" => "إجراء غير صالح."]);
            }
        }
    }

    private function syncFromFile()
    {
        $filePath = __DIR__ . '/../database/atten.jsonl';
        if (!file_exists($filePath)) {
            echo json_encode(["message" => "الملف غير موجود: لم يتم استلام أي بصمات من الجهاز بعد على هذا السيرفر."]);
            return;
        }

        $content = file_get_contents($filePath);
        // Split the content by JSON blocks
        $jsonBlocks = preg_split('/}\s*\n\s*{/', $content);

        $total_imported = 0;
        $total_updated = 0;
        $total_skipped = 0;
        $total_missing = 0;
        $total_processed_blocks = 0;

        // Cache all employees to avoid redundant DB calls in the loop
        $allEmployees = [];
        $stmtEmp = $this->db->prepare("SELECT id, special_start_time, special_end_time, is_flexible, required_hours FROM atk_employees");
        $stmtEmp->execute();
        while ($e = $stmtEmp->fetch(PDO::FETCH_ASSOC)) {
            $allEmployees[$e['id']] = $e;
        }

        $settings = $this->setting->getSettings();
        $default_start = $settings['default_start_time'] ?? '08:00:00';
        $default_end = $settings['default_end_time'] ?? '16:00:00';
        $allowed_late = $settings['allowed_late_minutes'] ?? 15;
        if (isset($settings['ramadan_mode']) && $settings['ramadan_mode'] == 1) {
            $default_start = $settings['ramadan_start_time'] ?? '10:00:00';
            $default_end = $settings['ramadan_end_time'] ?? '15:00:00';
        }

        $this->db->beginTransaction();
        try {
            foreach ($jsonBlocks as $block) {
                // Restore curly braces
                if (substr(trim($block), 0, 1) !== '{')
                    $block = '{' . $block;
                if (substr(trim($block), -1) !== '}')
                    $block = $block . '}';

                $log = json_decode($block, true);
                if (!$log)
                    continue;

                // Case A: New format with 'user_days'
                $dataToProcess = [];
                if (isset($log['user_days'])) {
                    $dataToProcess = $log['user_days'];
                }
                // Case B: Old format with 'users' (requires daily re-grouping)
                else if (isset($log['users'])) {
                    foreach ($log['users'] as $uid => $userRec) {
                        if (!isset($userRec['events']))
                            continue;
                        foreach ($userRec['events'] as $e) {
                            $d = date('Y-m-d', strtotime(substr($e['datetime_iso'], 0, 19)));
                            $key = $uid . "_" . $d;
                            if (!isset($dataToProcess[$key])) {
                                $dataToProcess[$key] = [
                                    "user_id" => $uid,
                                    "date" => $d,
                                    "first" => $e['datetime_iso'],
                                    "last" => $e['datetime_iso'],
                                    "count" => 0
                                ];
                            }
                            $dataToProcess[$key]["count"]++;
                            if ($e['datetime_iso'] < $dataToProcess[$key]["first"])
                                $dataToProcess[$key]["first"] = $e['datetime_iso'];
                            if ($e['datetime_iso'] > $dataToProcess[$key]["last"])
                                $dataToProcess[$key]["last"] = $e['datetime_iso'];
                        }
                    }
                }

                if (empty($dataToProcess))
                    continue;
                $total_processed_blocks++;

                foreach ($dataToProcess as $record) {
                    $empId = $record['user_id'];
                    $date = $record['date'];

                    if (!isset($allEmployees[$empId])) {
                        $total_missing++;
                        continue;
                    }

                    $empInfo = $allEmployees[$empId];
                    $checkIn = date('Y-m-d H:i:s', strtotime(substr($record['first'], 0, 19)));
                    $checkOut = ($record['count'] > 1) ? date('Y-m-d H:i:s', strtotime(substr($record['last'], 0, 19))) : null;

                    $calc = AttendanceCalculator::calculate($checkIn, $checkOut, $date, $empInfo, $settings);

                    $late_minutes = $calc['late_minutes'];
                    $early_exit_minutes = $calc['early_exit_minutes'];
                    $status = $calc['status'];

                    if (!$checkOut)
                        $status = 'incomplete';

                    $query = "INSERT INTO atk_attendance 
                              (employee_id, date, check_in, check_out, late_minutes, early_exit_minutes, status, source) 
                              VALUES (:emp_id, :b_date, :check_in, :check_out, :late, :early, :status, :source)
                              ON DUPLICATE KEY UPDATE 
                              check_out = VALUES(check_out),
                              status = VALUES(status),
                              late_minutes = VALUES(late_minutes),
                              early_exit_minutes = VALUES(early_exit_minutes)";

                    $stmt = $this->db->prepare($query);
                    $stmt->execute([
                        ":emp_id" => $empId,
                        ":b_date" => $date,
                        ":check_in" => $checkIn,
                        ":check_out" => $checkOut,
                        ":late" => $late_minutes,
                        ":early" => $early_exit_minutes,
                        ":status" => $status,
                        ":source" => 'file_sync'
                    ]);

                    $rows = $stmt->rowCount();
                    if ($rows == 1)
                        $total_imported++;
                    else if ($rows == 2)
                        $total_updated++;
                    else
                        $total_skipped++;
                }
            }
            $this->db->commit();
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(["message" => "فشلت المعاملة: " . $e->getMessage()]);
            return;
        }

        echo json_encode([
            "message" => "Success",
            "imported" => $total_imported,
            "updated" => $total_updated,
            "skipped" => $total_skipped,
            "unregistered" => $total_missing,
            "blocks" => $total_processed_blocks
        ]);
    }


    private function importJson()
    {
        $jsonData = '';
        if (isset($_FILES['file']['tmp_name'])) {
            $jsonData = file_get_contents($_FILES['file']['tmp_name']);
        } else {
            $rawBody = file_get_contents('php://input');
            $decodedBody = json_decode($rawBody, true);
            if ($decodedBody && isset($decodedBody['json'])) {
                $jsonData = $decodedBody['json'];
            } else {
                $jsonData = $rawBody;
            }
        }

        $data = json_decode($jsonData, true);
        if (!$data || !isset($data['users'])) {
            http_response_code(400);
            echo json_encode(["message" => "تنسيق JSON غير صالح. " . json_last_error_msg()]);
            return;
        }

        $settings = $this->setting->getSettings();
        $default_start = $settings['default_start_time'] ?? '08:00:00';
        $default_end = $settings['default_end_time'] ?? '16:00:00';
        $allowed_late = $settings['allowed_late_minutes'] ?? 15;
        if (isset($settings['ramadan_mode']) && $settings['ramadan_mode'] == 1) {
            $default_start = $settings['ramadan_start_time'] ?? '10:00:00';
            $default_end = $settings['ramadan_end_time'] ?? '15:00:00';
        }

        $imported = 0;
        $duplicates = 0;

        foreach ($data['users'] as $empId => $record) {
            $empInfo = $this->employee->readOne($empId);
            if (!$empInfo)
                continue; // Skip unknown employee

            if (!isset($record['events']) || count($record['events']) == 0)
                continue;

            $firstEventIso = $record['first'];
            $lastEventIso = $record['last'];
            $date = date('Y-m-d', strtotime(substr($firstEventIso, 0, 19)));

            $checkIn = date('Y-m-d H:i:s', strtotime(substr($firstEventIso, 0, 19)));
            $checkOut = null;
            if (count($record['events']) > 1) {
                $checkOut = date('Y-m-d H:i:s', strtotime(substr($lastEventIso, 0, 19)));
            }

            $calc = AttendanceCalculator::calculate($checkIn, $checkOut, $date, $empInfo, $settings);

            $late_minutes = $calc['late_minutes'];
            $early_exit_minutes = $calc['early_exit_minutes'];
            $status = $calc['status'];

            $this->attendance->employee_id = $empId;
            $this->attendance->date = $date;
            $this->attendance->check_in = $checkIn;
            $this->attendance->check_out = $checkOut;
            $this->attendance->late_minutes = $late_minutes;
            $this->attendance->early_exit_minutes = $early_exit_minutes;
            $this->attendance->status = $status;
            $this->attendance->source = 'json_import';

            if ($this->attendance->create()) {
                $imported++;
            } else {
                $duplicates++;
            }
        }

        echo json_encode(["message" => "اكتمل الاستيراد.", "imported" => $imported, "duplicates" => $duplicates]);
    }

    private function updateNote()
    {
        $input = json_decode(file_get_contents('php://input'), true);
        $id = $input['id'] ?? null;
        $notes = $input['notes'] ?? '';

        if (!$id) {
            http_response_code(400);
            echo json_encode(["message" => "معرف السجل مطلوب."]);
            return;
        }

        $query = "UPDATE atk_attendance SET notes = :notes WHERE id = :id";
        $stmt = $this->db->prepare($query);
        $stmt->bindParam(":notes", $notes);
        $stmt->bindParam(":id", $id);

        if ($stmt->execute()) {
            echo json_encode(["message" => "تم تحديث الملاحظة بنجاح."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "فشل تحديث الملاحظة."]);
        }
    }
}
?>