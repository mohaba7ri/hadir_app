<?php
require_once 'database/db.php';

$database = new Database();
$db = $database->getConnection();

try {
    $query = "ALTER TABLE atk_holidays ADD COLUMN is_recurring TINYINT(1) DEFAULT 0 AFTER end_date";
    $db->exec($query);
    echo json_encode(["status" => "success", "message" => "تمت إضافة عمود 'is_recurring' إلى 'atk_holidays' بنجاح."]);
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo json_encode(["status" => "success", "message" => "عمود 'is_recurring' موجود بالفعل."]);
    } else {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "خطأ في قاعدة البيانات: " . $e->getMessage()]);
    }
}
?>
