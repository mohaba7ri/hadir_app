<?php
require_once 'models/Vacation.php';
require_once 'fcm_v1_helper.php';

class VacationController
{
    private $db;
    private $vacation;
    private $fcm;

    public function __construct($db)
    {
        $this->db = $db;
        $this->vacation = new Vacation($db);
        // Use the newly uploaded service account file
        // Go up one directory to find the JSON in backend/
        $this->fcm = new FCMHelper(__DIR__ . '/../hadir-app-d5cfb-762235c5666e.json');
    }

    private function sendFCM($topic, $title, $body)
    {
        try {
            $result = $this->fcm->sendToTopic($topic, $title, $body, [
                'type' => 'vacation_update',
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
            ]);

            if ($result['status'] === 'success') {
                error_log("FCM Success for topic $topic: " . json_encode($result));
            } else {
                error_log("FCM Error for topic $topic: " . json_encode($result));
            }
            return $result;
        } catch (Exception $e) {
            error_log("FCM Exception: " . $e->getMessage());
            return false;
        }
    }

    public function processRequest($method, $id)
    {
        switch ($method) {
            case 'GET':
                $stmt = $this->vacation->readAll();
                $data = [];
                while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $data[] = $row;
                }
                echo json_encode($data);
                break;

            case 'POST':
                $isMultipart = strpos($_SERVER['CONTENT_TYPE'] ?? '', 'multipart/form-data') !== false;

                if ($isMultipart) {
                    $employee_id = $_POST['employee_id'] ?? null;
                    $start_date = $_POST['start_date'] ?? null;
                    $end_date = $_POST['end_date'] ?? null;
                    $total_days = $_POST['total_days'] ?? null;
                    $vacation_type = $_POST['vacation_type'] ?? 'إجازة سنوية';
                    $status = $_POST['status'] ?? 'pending';
                    $reason = $_POST['reason'] ?? null;
                    $is_admin = isset($_POST['is_admin']) ? filter_var($_POST['is_admin'], FILTER_VALIDATE_BOOLEAN) : false;
                    $is_hourly = isset($_POST['is_hourly']) ? filter_var($_POST['is_hourly'], FILTER_VALIDATE_BOOLEAN) : false;
                    $start_time = $_POST['start_time'] ?? null;
                    $end_time = $_POST['end_time'] ?? null;
                    $total_minutes = $_POST['total_minutes'] ?? 0;
                } else {
                    $rawInput = file_get_contents("php://input");
                    $data = json_decode($rawInput);
                    if (!$data) {
                        http_response_code(400);
                        echo json_encode(["message" => "بيانات JSON غير صالحة."]);
                        break;
                    }
                    $employee_id = $data->employee_id ?? null;
                    $start_date = $data->start_date ?? null;
                    $end_date = $data->end_date ?? null;
                    $total_days = $data->total_days ?? null;
                    $vacation_type = $data->vacation_type ?? 'إجازة سنوية';
                    $status = $data->status ?? 'pending';
                    $reason = $data->reason ?? null;
                    $is_admin = isset($data->is_admin) ? filter_var($data->is_admin, FILTER_VALIDATE_BOOLEAN) : false;
                    $is_hourly = isset($data->is_hourly) ? filter_var($data->is_hourly, FILTER_VALIDATE_BOOLEAN) : false;
                    $start_time = $data->start_time ?? null;
                    $end_time = $data->end_time ?? null;
                    $total_minutes = $data->total_minutes ?? 0;
                }

                if (empty($total_minutes) && !empty($total_days)) {
                    $stmt = $this->db->prepare("SELECT special_start_time, special_end_time FROM atk_employees WHERE id = ?");
                    $stmt->execute([$employee_id]);
                    $emp = $stmt->fetch(PDO::FETCH_ASSOC);
                    $minutesPerDay = 480;
                    if ($emp && !empty($emp['special_start_time']) && !empty($emp['special_end_time'])) {
                        $st = strtotime("2000-01-01 " . $emp['special_start_time']);
                        $et = strtotime("2000-01-01 " . $emp['special_end_time']);
                        $minutesPerDay = ($et - $st) / 60;
                    }
                    $total_minutes = $total_days * $minutesPerDay;
                }

                $hasRequiredFields = !empty($employee_id) && !empty($start_date) && !empty($end_date);
                $hasAmount = !empty($total_days) || !empty($total_minutes);

                if ($hasRequiredFields && $hasAmount) {
                    try {
                        // Explicitly check for ANY pending request overlapping this period
                        $checkStmt = $this->db->prepare("SELECT id FROM atk_vacations WHERE employee_id = ? AND status = 'pending' AND start_date <= ? AND end_date >= ?");
                        $checkStmt->execute([$employee_id, $end_date, $start_date]);
                        if ($checkStmt->fetch()) {
                            http_response_code(400);
                            echo json_encode(["status" => "error", "message" => "يوجد طلب إجازة قيد الانتظار لهذا الموظف في هذا التاريخ. يرجى مراجعته أو اعتماده من شاشة طلبات الإجازة أولاً."]);
                            break;
                        }

                        if ($vacation_type === 'إجازة سنوية') {
                            $limitStmt = $this->db->prepare("SELECT monthly_annual_leave_limit_minutes FROM atk_employees WHERE id = ?");
                            $limitStmt->execute([$employee_id]);
                            $limitEmp = $limitStmt->fetch(PDO::FETCH_ASSOC);
                            $monthlyLimit = $limitEmp ? (int) ($limitEmp['monthly_annual_leave_limit_minutes'] ?? 750) : 750;

                            $dt = new DateTime($start_date);
                            $day = (int) $dt->format('d');
                            $month = (int) $dt->format('m');
                            $year = (int) $dt->format('Y');

                            if ($day >= 25) {
                                $month++;
                                if ($month > 12) {
                                    $month = 1;
                                    $year++;
                                }
                            }

                            if ($month == 1) {
                                $start_month = 12;
                                $start_year = $year - 1;
                            } else {
                                $start_month = $month - 1;
                                $start_year = $year;
                            }
                            $cycle_start = sprintf('%04d-%02d-25', $start_year, $start_month);
                            $cycle_end = sprintf('%04d-%02d-24', $year, $month);

                            $sumStmt = $this->db->prepare("SELECT SUM(total_minutes) as used_minutes FROM atk_vacations WHERE employee_id = ? AND vacation_type = 'إجازة سنوية' AND start_date >= ? AND start_date <= ? AND status != 'rejected'");
                            $sumStmt->execute([$employee_id, $cycle_start, $cycle_end]);
                            $sumRow = $sumStmt->fetch(PDO::FETCH_ASSOC);
                            $usedMinutes = $sumRow ? (int) ($sumRow['used_minutes'] ?? 0) : 0;

                            if (($usedMinutes + $total_minutes) > $monthlyLimit) {
                                $remaining = $monthlyLimit - $usedMinutes;
                                $remText = $remaining > 0 ? "يتبقى لك " . number_format($remaining / 60, 2) . " ساعة فقط." : "لقد استنفدت الحد المسموح.";
                                http_response_code(400);
                                echo json_encode(["status" => "error", "message" => "لقد تجاوزت الحد الشهري للإجازة السنوية (" . number_format($monthlyLimit / 60, 2) . " ساعة). $remText"]);
                                break;
                            }
                        }

                        if ($this->vacation->hasConflictingVacation($employee_id, $start_date, $end_date, $is_hourly)) {
                            http_response_code(400);
                            echo json_encode(["status" => "error", "message" => "عذراً، يوجد تداخل في التواريخ: لديك طلب إجازة معتمد سابق خلال هذه attendace."]);
                            break;
                        }

                        if (!$is_admin && $vacation_type === 'إعفاء') {
                            http_response_code(403);
                            echo json_encode(["status" => "error", "message" => "عذراً، هذا النوع من الإجازات مخصص للمدير العام فقط."]);
                            break;
                        }

                        if (!$is_admin && $vacation_type !== 'إجازة سنوية' && (!isset($_FILES['attachment']) || $_FILES['attachment']['error'] !== UPLOAD_ERR_OK)) {
                            http_response_code(400);
                            echo json_encode(["status" => "error", "message" => "عذراً، يجب إرفاق ملف لهذا النوع من الطلبات."]);
                            break;
                        }

                        $attachmentPath = null;
                        if (isset($_FILES['attachment']) && $_FILES['attachment']['error'] === UPLOAD_ERR_OK) {
                            $uploadDir = __DIR__ . '/../uploads/vacations/';
                            if (!is_dir($uploadDir))
                                mkdir($uploadDir, 0777, true);

                            $fileExt = pathinfo($_FILES['attachment']['name'], PATHINFO_EXTENSION);
                            $fileName = time() . '_' . $employee_id . '.' . $fileExt;
                            $targetFile = $uploadDir . $fileName;

                            if (move_uploaded_file($_FILES['attachment']['tmp_name'], $targetFile)) {
                                $attachmentPath = 'uploads/vacations/' . $fileName;
                            }
                        }

                        $this->vacation->employee_id = $employee_id;
                        $this->vacation->start_date = $start_date;
                        $this->vacation->end_date = $end_date;
                        $this->vacation->total_days = $total_days;
                        $this->vacation->vacation_type = $vacation_type;
                        $this->vacation->status = $status;
                        $this->vacation->attachment = $attachmentPath;
                        $this->vacation->reason = $reason;
                        $this->vacation->is_hourly = $is_hourly;
                        $this->vacation->start_time = $start_time;
                        $this->vacation->end_time = $end_time;
                        $this->vacation->total_minutes = $total_minutes;

                        if ($this->vacation->create()) {
                            $employee_name = $this->vacation->getEmployeeName($employee_id);
                            $this->sendFCM('admin_notifications', 'طلب إجازة جديد', "الموظف ({$employee_name}) قدم طلب إجازة جديد ({$vacation_type})");
                            http_response_code(201);
                            echo json_encode(["message" => "تم طلب الإجازة."]);
                        } else {
                            http_response_code(503);
                            echo json_encode(["message" => "تعذر إنشاء الطلب."]);
                        }
                    } catch (Exception $e) {
                        http_response_code(500);
                        echo json_encode(["message" => "خطأ في الخادم: " . $e->getMessage()]);
                    }
                } else {
                    http_response_code(400);
                    echo json_encode(["message" => "البيانات غير مكتملة."]);
                }
                break;

            case 'PUT':
                $data = json_decode(file_get_contents("php://input"));
                if (!empty($id) && !empty($data->status)) {
                    // Fetch details before update to get employee_id
                    $vacationDetails = $this->vacation->getVacationDetails($id);

                    if (!$vacationDetails) {
                        http_response_code(404);
                        echo json_encode(["message" => "طلب الإجازة غير موجود."]);
                        break;
                    }

                    $notes = $data->notes ?? null;

                    if ($this->vacation->updateStatus($id, $data->status, $notes)) {
                        $statusText = $data->status == 'approved' ? 'قبول 🎉' : 'رفض ❌';
                        $this->sendFCM(
                            "employee_" . $vacationDetails['employee_id'],
                            "تحديث طلب الإجازة (" . ($vacationDetails['employee_name'] ?? '') . ")",
                            "تم $statusText طلبك المقدم بتاريخ " . $vacationDetails['start_date']
                        );

                        http_response_code(200);
                        echo json_encode(["message" => "تم تحديث الحالة وإرسال الإشعار."]);
                    } else {
                        http_response_code(503);
                        echo json_encode(["message" => "تعذر تحديث الحالة."]);
                    }
                } else {
                    http_response_code(400);
                    echo json_encode(["message" => "المعرف والحالة مطلوبان."]);
                }
                break;

            case 'DELETE':
                if (!empty($id)) {
                    $result = $this->vacation->deleteVacation($id);
                    if ($result['success']) {
                        http_response_code(200);
                        echo json_encode(["message" => $result['message']]);
                    } else {
                        http_response_code(400);
                        echo json_encode(["message" => $result['message']]);
                    }
                } else {
                    http_response_code(400);
                    echo json_encode(["message" => "المعرف مطلوب."]);
                }
                break;

            default:
                http_response_code(405);
                echo json_encode(["message" => "الطريقة غير مسموح بها"]);
        }
    }
}
?>