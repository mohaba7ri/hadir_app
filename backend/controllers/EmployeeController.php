<?php
require_once 'models/Employee.php';

class EmployeeController {
    private $db;
    private $employee;

    public function __construct($db) {
        $this->db = $db;
        $this->employee = new Employee($db);
    }

    public function processRequest($method, $id) {
        switch ($method) {
            case 'GET':
                if ($id) {
                    $result = $this->employee->readOne($id);
                    if ($result) {
                        echo json_encode($result);
                    } else {
                        http_response_code(404);
                        echo json_encode(array("message" => "الموظف غير موجود."));
                    }
                } else {
                    $dept_id = isset($_GET['department_id']) ? $_GET['department_id'] : null;
                    $stmt = $this->employee->readAll($dept_id);
                    $employees_arr = array();
                    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                        array_push($employees_arr, $row);
                    }
                    echo json_encode($employees_arr);
                }
                break;
            case 'POST':
                $data = json_decode(file_get_contents("php://input"));
                if (!$data) {
                    http_response_code(400);
                    echo json_encode(array("message" => "بيانات JSON غير صالحة."));
                    break;
                }

                if (!empty($data->name)) {
                    try {
                        $this->employee->id = $data->id ?? null;
                        $this->employee->name = $data->name;
                        $this->employee->salary = $data->salary ?? 0;
                        $this->employee->special_start_time = !empty($data->special_start_time) ? $data->special_start_time : null;
                        $this->employee->special_end_time = !empty($data->special_end_time) ? $data->special_end_time : null;
                        $this->employee->vacation_credit = isset($data->vacation_credit) ? $data->vacation_credit : 30;
                        $this->employee->work_days_per_week = isset($data->work_days_per_week) ? $data->work_days_per_week : 6;
                        $this->employee->status = $data->status ?? 'active';
                        $this->employee->password = $data->password ?? '123';
                        $this->employee->is_flexible = !empty($data->is_flexible) ? 1 : 0;
                        $this->employee->required_hours = $data->required_hours ?? 8.00;
                        $this->employee->department_id = $data->department_id ?? null;
                        $this->employee->monthly_annual_leave_limit_minutes = $data->monthly_annual_leave_limit_minutes ?? 750;

                        if ($this->employee->create()) {
                            http_response_code(201);
                            echo json_encode(array("message" => "تم إنشاء حساب الموظف."));
                        } else {
                            http_response_code(503);
                            echo json_encode(array("message" => "تعذر إنشاء الموظف."));
                        }
                    } catch (PDOException $e) {
                        http_response_code(500);
                        echo json_encode(array("message" => "خطأ في قاعدة البيانات: " . $e->getMessage()));
                    } catch (Exception $e) {
                        http_response_code(500);
                        echo json_encode(array("message" => "خطأ في الخادم: " . $e->getMessage()));
                    }
                } else {
                    http_response_code(400);
                    echo json_encode(array("message" => "البيانات غير مكتملة. الاسم مطلوب."));
                }
                break;
            case 'PUT':
                $data = json_decode(file_get_contents("php://input"));
                if (!$data) {
                    http_response_code(400);
                    echo json_encode(array("message" => "بيانات JSON غير صالحة."));
                    break;
                }

                if (!empty($id)) {
                    try {
                        $this->employee->id = $id;
                        $this->employee->name = $data->name ?? null;
                        $this->employee->salary = $data->salary ?? 0;
                        $this->employee->special_start_time = !empty($data->special_start_time) ? $data->special_start_time : null;
                        $this->employee->special_end_time = !empty($data->special_end_time) ? $data->special_end_time : null;
                        $this->employee->vacation_credit = isset($data->vacation_credit) ? $data->vacation_credit : 30;
                        $this->employee->work_days_per_week = isset($data->work_days_per_week) ? $data->work_days_per_week : 6;
                        $this->employee->status = $data->status ?? 'active';
                        $this->employee->password = $data->password ?? '123';
                        $this->employee->is_flexible = !empty($data->is_flexible) ? 1 : 0;
                        $this->employee->required_hours = $data->required_hours ?? 8.00;
                        $this->employee->department_id = $data->department_id ?? null;
                        $this->employee->monthly_annual_leave_limit_minutes = $data->monthly_annual_leave_limit_minutes ?? 750;

                        if ($this->employee->update()) {
                            http_response_code(200);
                            echo json_encode(array("message" => "تم تحديث بيانات الموظف."));
                        } else {
                            http_response_code(503);
                            echo json_encode(array("message" => "تعذر تحديث الموظف."));
                        }
                    } catch (PDOException $e) {
                        http_response_code(500);
                        echo json_encode(array("message" => "خطأ في قاعدة البيانات: " . $e->getMessage()));
                    } catch (Exception $e) {
                        http_response_code(500);
                        echo json_encode(array("message" => "خطأ في الخادم: " . $e->getMessage()));
                    }
                } else {
                    http_response_code(400);
                    echo json_encode(array("message" => "المعرف مطلوب."));
                }
                break;
            case 'DELETE':
                if (!empty($id)) {
                    $this->employee->id = $id;
                    if ($this->employee->delete()) {
                        http_response_code(200);
                        echo json_encode(array("message" => "تم حذف الموظف."));
                    } else {
                        http_response_code(503);
                        echo json_encode(array("message" => "تعذر حذف الموظف."));
                    }
                } else {
                    http_response_code(400);
                    echo json_encode(array("message" => "المعرف مطلوب."));
                }
                break;
            default:
                http_response_code(405);
                echo json_encode(array("message" => "الطريقة غير مسموح بها."));
                break;
        }
    }
}
?>
