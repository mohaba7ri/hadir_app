<?php

require_once 'models/Report.php';

class ReportController
{
    private $db;
    private $report;

    public function __construct($db)
    {
        $this->db = $db;
        $this->report = new Report($db);
    }

    public function processRequest($method, $type)
    {
        if ($method === 'GET') {
            switch ($type) {
                case 'attendance':
                    $stmt = $this->report->getAttendanceReport();
                    break;
                case 'salary':
                    $stmt = $this->report->getSalaryReport();
                    break;
                case 'vacation':
                    $stmt = $this->report->getVacationReport();
                    break;
                case 'late':
                    $stmt = $this->report->getLateReport();
                    break;
                case 'employee-closings':
                    $employee_id = $_GET['employee_id'] ?? null;
                    if (!$employee_id) {
                        http_response_code(400);
                        echo json_encode(["status" => "error", "message" => "employee_id is required"]);
                        return;
                    }
                    $stmt = $this->report->getEmployeeClosings($employee_id);
                    break;
                case 'send_broadcast':
                    require_once 'fcm_v1_helper.php';
                    $fcm = new FCMHelper(__DIR__ . '/../hadir-app-d5cfb-762235c5666e.json');
                    $title = $_GET['title'] ?? 'تحديث هام للمنظومة';
                    $message = $_GET['message'] ?? 'يجب عليك تحديث التطبيق الآن لضمان استمرارية الخدمة.';
                    $url = $_GET['url'] ?? '';

                    if (empty($url)) {
                        http_response_code(400);
                        echo json_encode(["status" => "error", "message" => "الرابط مطلوب."]);
                        return;
                    }

                    $res = $fcm->sendToTopic('all_users', $title, $message, [
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        'force_update_url' => $url
                    ]);

                    // PERSISTENCE: Save to settings so new/manual app opens also see the update
                    if ($res['status'] === 'success') {
                        require_once 'models/Setting.php';
                        $s = new Setting($this->db);
                        $current = $s->getSettings();
                        $s->id = 1;
                        $s->default_start_time = $current['default_start_time'];
                        $s->allowed_late_minutes = $current['allowed_late_minutes'];
                        $s->ramadan_start_time = $current['ramadan_start_time'];
                        $s->ramadan_end_time = $current['ramadan_end_time'];
                        $s->ramadan_mode = $current['ramadan_mode'];
                        $s->default_end_time = $current['default_end_time'];
                        $s->last_renewal_year = $current['last_renewal_year'];
                        // Increment version to trigger update
                        $s->min_version = ($current['min_version'] ?? 1) + 1;
                        $s->force_update_url = $url;
                        $s->update();
                    }

                    echo json_encode($res);
                    return;
                default:
                    http_response_code(400);
                    echo json_encode(["message" => "نوع التقرير غير صالح."]);
                    return;
            }
            require_once 'models/Setting.php';
            $setting_model = new Setting($this->db);
            $settings = $setting_model->getSettings();

            $data = [];
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                if ($type === 'salary') {
                    // Determine workday duration
                    $start_time = (!empty($row['special_start_time'])) ? $row['special_start_time'] : (($settings['ramadan_mode'] == 1) ? $settings['ramadan_start_time'] : $settings['default_start_time']);
                    $end_time = (!empty($row['special_end_time'])) ? $row['special_end_time'] : (($settings['ramadan_mode'] == 1) ? $settings['ramadan_end_time'] : $settings['default_end_time']);

                    try {
                        $start = new DateTime($start_time);
                        $end = new DateTime($end_time);
                        if ($end < $start) {
                            $end->modify('+1 day'); // workday crosses midnight
                        }
                        $diff = $start->diff($end);
                        $work_hours = $diff->h + ($diff->i / 60) + ($diff->s / 3600);
                    } catch (Exception $e) {
                        $work_hours = 8;
                    }

                    if ($work_hours <= 0)
                        $work_hours = 8;

                    $divisor = intval(date('t'));
                    $daily_salary = floatval($row['salary']) / $divisor;
                    $absent_days = intval($row['absent_days']);
                    $late_mins = intval($row['total_late_minutes']);

                    $absence_deductions = $absent_days * $daily_salary;
                    // Formula: Discount per minute = (Salary / 30 days) / WorkHoursPerDay / 60
                    $late_deductions = $late_mins * ($daily_salary / $work_hours / 60);

                    $early_exit_mins = intval($row['total_early_exit_minutes'] ?? 0);
                    $early_exit_deductions = $early_exit_mins * ($daily_salary / $work_hours / 60);

                    $final_salary = floatval($row['salary']) - $absence_deductions - $late_deductions - $early_exit_deductions;

                    $row['final_salary'] = $final_salary;
                    $row['absence_deductions'] = $absence_deductions;
                    $row['late_deductions'] = $late_deductions;
                    $row['early_exit_deductions'] = $early_exit_deductions;
                    $row['work_hours'] = $work_hours;
                }

                $data[] = $row;
            }
            echo json_encode($data);
        } else if ($method === 'POST') {
            if ($type === 'split-payroll') {
                $input = json_decode(file_get_contents('php://input'), true);
                $employee_id = $input['employee_id'] ?? null;
                $month = $input['month'] ?? null;
                $year = $input['year'] ?? null;
                $start_date = $input['start_date'] ?? null;
                $end_date = $input['end_date'] ?? null;

                if (!$employee_id || !$month || !$year || !$end_date) {
                    http_response_code(400);
                    echo json_encode(["status" => "error", "message" => "All parameters (employee_id, month, year, end_date) are required."]);
                    return;
                }

                require_once __DIR__ . '/../services/AttendanceEngine.php';
                $engine = new AttendanceEngine($this->db);

                $result = $engine->autoClosePastMonths($employee_id, $start_date, $end_date);
                if ($result['status'] === 'success' || $result['status'] === 'duplicate') {
                    // We treat duplicate as success now because skipping duplicates is the expected behavior
                    echo json_encode(["status" => "success", "message" => "تم الإغلاق بنجاح.", "data" => $result]);
                } else {
                    http_response_code(400);
                    echo json_encode(["status" => "error", "message" => $result['message'] ?? "لا توجد بيانات للإغلاق أو حدث خطأ.", "duplicates" => []]);
                }
                return;
            } else if ($type === 'detailed-attendance') {
                $input = json_decode(file_get_contents('php://input'), true);
                $employee_id = $input['employee_id'] ?? null;
                $start_date = $input['start_date'] ?? null; // Optional
                $end_date = $input['end_date'] ?? null;     // Optional

                if (!$employee_id) {
                    http_response_code(400);
                    echo json_encode(["status" => "error", "message" => "employee_id is required."]);
                    return;
                }

                require_once __DIR__ . '/../services/AttendanceEngine.php';
                $engine = new AttendanceEngine($this->db);

                // If we want a range, we can just find all months that overlap the range and combine their summaries
                // Or if no range is given, find the first attendance record date and use today as end date
                if (!$start_date || !$end_date) {
                    $start_date = "2024-01-01"; // arbitrary early start
                    $end_date = date("Y-m-d");
                }

                $s = new DateTime($start_date);
                $e = new DateTime($end_date);

                $final_days = [];
                $final_totals = [];

                // Loop through all cycle months involved
                // A cycle is from 25th of M-1 to 24th of M.
                // We'll just generate the monthly summaries for all months from the start date's month to the end date's month + 1
                $current = new DateTime($s->format('Y-m-25'));
                $current->modify('-1 month'); // Start slightly before to catch the 25th

                $endLimit = new DateTime($e->format('Y-m-24'));
                $endLimit->modify('+1 month'); // End slightly after

                while ($current <= $endLimit) {
                    $m = (int) $current->format('m');
                    $y = (int) $current->format('Y');

                    // The engine's month is the month of the 24th.
                    // So if current is 2026-06-25, the cycle ends in 07-24 (month 7)
                    $cycle_month = $m;
                    if ($current->format('d') >= 25) {
                        $cycle_month++;
                        if ($cycle_month > 12) {
                            $cycle_month = 1;
                        }
                    }
                    $cycle_year = $y;
                    if ($m == 12 && $current->format('d') >= 25) {
                        $cycle_year++;
                    }

                    $summary = $engine->getMonthlySummary($employee_id, $cycle_month, $cycle_year);
                    if ($summary && isset($summary['days'])) {
                        foreach ($summary['days'] as $day) {
                            // Filter by exact requested range
                            if ($day['date'] >= $start_date && $day['date'] <= $end_date) {
                                // Prevent duplicates by checking if date already exists
                                $date_exists = false;
                                foreach ($final_days as $existing) {
                                    if ($existing['date'] === $day['date']) {
                                        $date_exists = true;
                                        break;
                                    }
                                }
                                if (!$date_exists) {
                                    $final_days[] = $day;
                                }
                            }
                        }
                    }
                    $current->modify('+1 month');
                }

                // Sort by date descending to match UI expectations
                usort($final_days, function ($a, $b) {
                    return strcmp($b['date'], $a['date']);
                });

                echo json_encode([
                    "status" => "success",
                    "days" => $final_days
                ]);
                return;
            } else {
                http_response_code(405);
                echo json_encode(["message" => "الطريقة غير مسموح بها."]);
            }
        } else {
            http_response_code(405);
            echo json_encode(["message" => "الطريقة غير مسموح بها."]);
        }
    }
}
?>