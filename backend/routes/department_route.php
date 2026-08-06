<?php
require_once 'models/Department.php';

$department = new Department($db);
$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        $stmt = $department->read();
        $departments = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode($departments);
        break;

    case 'POST':
        $data = json_decode(file_get_contents("php://input"));
        if(!empty($data->name)) {
            $department->name = $data->name;
            if($department->create()) {
                http_response_code(201);
                echo json_encode(["message" => "تم إنشاء الإدارة."]);
            } else {
                http_response_code(500);
                echo json_encode(["message" => "تعذر إنشاء الإدارة."]);
            }
        } else {
            http_response_code(400);
            echo json_encode(["message" => "البيانات غير مكتملة."]);
        }
        break;

    case 'PUT':
        $data = json_decode(file_get_contents("php://input"));
        if(!empty($data->id) && !empty($data->name)) {
            $department->id = $data->id;
            $department->name = $data->name;
            if($department->update()) {
                echo json_encode(["message" => "تم تحديث الإدارة."]);
            } else {
                http_response_code(500);
                echo json_encode(["message" => "تعذر تحديث الإدارة."]);
            }
        } else {
            http_response_code(400);
            echo json_encode(["message" => "البيانات غير مكتملة."]);
        }
        break;

    case 'DELETE':
        if($id) {
            $department->id = $id;
            if($department->delete()) {
                echo json_encode(["message" => "تم حذف الإدارة."]);
            } else {
                http_response_code(500);
                echo json_encode(["message" => "تعذر حذف الإدارة."]);
            }
        } else {
            http_response_code(400);
            echo json_encode(["message" => "المعرف مفقود."]);
        }
        break;
}
?>
