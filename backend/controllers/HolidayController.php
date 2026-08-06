<?php
require_once 'models/Holiday.php';

class HolidayController {
    private $db;
    private $holiday;

    public function __construct($db) {
        $this->db = $db;
        $this->holiday = new Holiday($db);
    }

    public function processRequest($method, $type, $id) {
        if ($type === 'weekly') {
            if ($method === 'GET') {
                $stmt = $this->holiday->getWeeklyHolidays();
                $data = [];
                while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $data[] = $row;
                }
                echo json_encode($data);
            } else if ($method === 'PUT') {
                $data = json_decode(file_get_contents("php://input"));
                if (isset($data->days) && is_array($data->days)) {
                    if ($this->holiday->updateWeeklyHolidays($data->days)) {
                        http_response_code(200);
                        echo json_encode(["message" => "تم تحديث العطلات الأسبوعية."]);
                    } else {
                        http_response_code(503);
                        echo json_encode(["message" => "تعذر تحديث العطلات الأسبوعية."]);
                    }
                }
            } else {
                http_response_code(405);
                echo json_encode(["message" => "الطريقة غير مسموح بها"]);
            }
        } else {
            // General holidays
            if ($method === 'GET') {
                $stmt = $this->holiday->getHolidays();
                $data = [];
                while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $data[] = $row;
                }
                echo json_encode($data);
            } else if ($method === 'POST') {
                $data = json_decode(file_get_contents("php://input"));
                if (!empty($data->name) && !empty($data->date)) {
                    $end_date = !empty($data->end_date) ? $data->end_date : $data->date;
                    $is_recurring = isset($data->is_recurring) ? intval($data->is_recurring) : 0;
                    if ($this->holiday->createHoliday($data->name, $data->date, $end_date, $is_recurring)) {
                        http_response_code(201);
                        echo json_encode(["message" => "تم إنشاء الإجازة."]);
                    } else {
                        http_response_code(503);
                        echo json_encode(["message" => "تعذر إنشاء الإجازة."]);
                    }
                } else {
                    http_response_code(400);
                    echo json_encode(["message" => "البيانات غير مكتملة."]);
                }
            } else if ($method === 'DELETE') {
                if (!empty($id)) {
                    if ($this->holiday->deleteHoliday($id)) {
                        http_response_code(200);
                        echo json_encode(["message" => "تم حذف الإجازة."]);
                    } else {
                        http_response_code(503);
                        echo json_encode(["message" => "تعذر حذف الإجازة."]);
                    }
                } else {
                    http_response_code(400);
                    echo json_encode(["message" => "المعرف مطلوب."]);
                }
            } else {
                http_response_code(405);
                echo json_encode(["message" => "الطريقة غير مسموح بها"]);
            }
        }
    }
}
?>
