<?php
require_once 'database/db.php';

$database = new Database();
$db = $database->getConnection();

try {
    $query = "ALTER TABLE atk_employees ADD COLUMN work_days_per_week INT DEFAULT 6 AFTER vacation_credit";
    $db->exec($query);
    echo json_encode(["status" => "success", "message" => "تمت إضافة عمود 'work_days_per_week' بنجاح."]);
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo json_encode(["status" => "success", "message" => "عمود 'work_days_per_week' موجود بالفعل."]);
    } else {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "خطأ في قاعدة البيانات: " . $e->getMessage()]);
    }
}
?>
