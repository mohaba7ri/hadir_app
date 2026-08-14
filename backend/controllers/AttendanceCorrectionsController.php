<?php
require_once 'models/AttendanceCorrection.php';

class AttendanceCorrectionsController {
    private $db;
    private $correction;

    public function __construct($db) {
        $this->db = $db;
        $this->correction = new AttendanceCorrection($db);
    }

    public function processRequest($method, $id) {
        switch ($method) {
            case 'GET':
                $emp_id = $_GET['employee_id'] ?? null;
                $stmt = $this->correction->getAll($emp_id);
                $requests = array();
                while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    array_push($requests, $row);
                }
                echo json_encode($requests);
                break;

            case 'POST':
                // Check if it's an update status request (based on URL pattern or payload)
                $data = json_decode(file_get_contents("php://input"));
                
                // If ID is provided, it's an update. Wait, our route passes ID
                if ($id) {
                    if (empty($data->status)) {
                        http_response_code(400);
                        echo json_encode(array("message" => "الحالة مطلوبة."));
                        break;
                    }
                    $admin_id = $data->admin_id ?? 1; // Fallback to 1 if not provided
                    if ($this->correction->updateStatus($id, $data->status, $data->admin_note ?? "", $admin_id)) {
                        echo json_encode(array("message" => "تم تحديث طلب التصحيح."));
                    } else {
                        http_response_code(503);
                        echo json_encode(array("message" => "تعذر تحديث الطلب."));
                    }
                    break;
                }

                // Otherwise, it's a creation
                if (!$data || empty($data->employee_id) || empty($data->date) || empty($data->type) || empty($data->requested_time)) {
                    http_response_code(400);
                    echo json_encode(array("message" => "البيانات غير مكتملة."));
                    break;
                }

                // Prevent duplicates
                if ($this->correction->getPendingCountForDate($data->employee_id, $data->date) > 0) {
                    http_response_code(400);
                    echo json_encode(array("status" => "error", "message" => "يوجد طلب تصحيح معلق لهذا اليوم."));
                    break;
                }

                // Prevent if date is in closed month
                if ($this->correction->isDateClosed($data->employee_id, $data->date)) {
                    http_response_code(400);
                    echo json_encode(array("status" => "error", "message" => "لا يمكن إجراء تصحيح بصمات لأن هذا اليوم يقع ضمن شهر تم إغلاقه (الإغلاق الشهري)."));
                    break;
                }

                $this->correction->employee_id = $data->employee_id;
                $this->correction->date = $data->date;
                $this->correction->type = $data->type;
                $this->correction->original_time = $data->original_time ?? null;
                $this->correction->requested_time = $data->requested_time;
                $this->correction->reason = $data->reason ?? "";
                if (!empty($data->status)) {
                    $this->correction->status = $data->status;
                } elseif (isset($data->is_admin) && filter_var($data->is_admin, FILTER_VALIDATE_BOOLEAN)) {
                    $this->correction->status = 'approved';
                }

                if ($this->correction->create()) {
                    http_response_code(201);
                    echo json_encode(array("message" => "تم إرسال طلب التصحيح بنجاح."));
                } else {
                    http_response_code(503);
                    echo json_encode(array("message" => "تعذر إرسال الطلب."));
                }
                break;
                
            case 'PUT':
                // Optional PUT for status update
                $data = json_decode(file_get_contents("php://input"));
                if (!$id || empty($data->status)) {
                    http_response_code(400);
                    echo json_encode(array("message" => "المعرف والحالة مطلوبان."));
                    break;
                }
                $admin_id = $data->admin_id ?? 1;
                if ($this->correction->updateStatus($id, $data->status, $data->admin_note ?? "", $admin_id)) {
                    echo json_encode(array("message" => "تم تحديث الطلب."));
                } else {
                    http_response_code(503);
                    echo json_encode(array("message" => "تعذر تحديث الطلب."));
                }
                break;
        }
    }
}
?>
