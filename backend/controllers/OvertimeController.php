<?php
require_once 'models/OvertimeRequest.php';
require_once 'models/Employee.php';

class OvertimeController {
    private $db;
    private $overtime;
    private $employee;

    public function __construct($db) {
        $this->db = $db;
        $this->overtime = new OvertimeRequest($db);
        $this->employee = new Employee($db);
    }

    public function processRequest($method, $id) {
        switch ($method) {
            case 'GET':
                $emp_id = $_GET['employee_id'] ?? null;
                $stmt = $this->overtime->getAllRequests($emp_id);
                $requests = array();
                while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    array_push($requests, $row);
                }
                echo json_encode($requests);
                break;

            case 'POST':
                $data = json_decode(file_get_contents("php://input"));
                if (!$data || empty($data->employee_id) || empty($data->date) || empty($data->start_time) || empty($data->end_time)) {
                    http_response_code(400);
                    echo json_encode(array("message" => "البيانات غير مكتملة."));
                    break;
                }

                // 1. Validation: Overlap check
                if (!$this->isValidOvertime($data)) {
                    http_response_code(400);
                    echo json_encode(array("status" => "error", "message" => "يتداخل وقت العمل الإضافي المطلوب مع ساعات العمل العادية."));
                    break;
                }

                $this->overtime->employee_id = $data->employee_id;
                $this->overtime->date = $data->date;
                $this->overtime->start_time = $data->start_time;
                $this->overtime->end_time = $data->end_time;
                $this->overtime->reason = $data->reason ?? "";
                $this->overtime->status = 'pending';

                if ($this->overtime->create()) {
                    http_response_code(201);
                    echo json_encode(array("message" => "تم تقديم طلب العمل الإضافي."));
                } else {
                    http_response_code(503);
                    echo json_encode(array("message" => "تعذر إرسال الطلب."));
                }
                break;

            case 'PUT':
                $data = json_decode(file_get_contents("php://input"));
                if (!$id || empty($data->status)) {
                    http_response_code(400);
                    echo json_encode(array("message" => "المعرف والحالة مطلوبان."));
                    break;
                }

                if ($this->overtime->updateStatus($id, $data->status, $data->admin_note ?? "")) {
                    echo json_encode(array("message" => "تم تحديث الطلب."));
                } else {
                    http_response_code(503);
                    echo json_encode(array("message" => "تعذر تحديث الطلب."));
                }
                break;
        }
    }

    private function isValidOvertime($data) {
        // Fetch employee to get work schedule
        $empData = $this->employee->readOne($data->employee_id);
        if (!$empData) return false;

        // Fetch global settings
        $q = "SELECT * FROM atk_settings LIMIT 1";
        $s = $this->db->prepare($q);
        $s->execute();
        $settings = $s->fetch(PDO::FETCH_ASSOC);

        $isRamadan = $settings['ramadan_mode'] ?? false;
        
        // Determine scheduled work hours
        $workStart = $empData['special_start_time'] ?? ($isRamadan ? $settings['ramadan_start_time'] : $settings['default_start_time']);
        $workEnd = $empData['special_end_time'] ?? ($isRamadan ? $settings['ramadan_end_time'] : $settings['default_end_time']);

        $reqStart = $data->start_time;
        $reqEnd = $data->end_time;

        // Simple overlap logic:
        // Overtime is valid if: (OvertimeEnd <= WorkStart) OR (OvertimeStart >= WorkEnd)
        // Note: This assumes overtime and work are on the same calendar day.
        
        $ws = strtotime($workStart);
        $we = strtotime($workEnd);
        $rs = strtotime($reqStart);
        $re = strtotime($reqEnd);

        // If overtime crosses midnight, this logic needs adjustment, but for standard day:
        if ($re <= $ws || $rs >= $we) {
            return true;
        }

        return false;
    }
}
?>
