<?php
require_once 'database/db.php';

$database = new Database();
$db = $database->getConnection();

try {
    $query = "ALTER TABLE atk_holidays ADD COLUMN end_date DATE NULL AFTER date";
    $db->exec($query);
    // For existing records, set end_date = date
    $db->exec("UPDATE atk_holidays SET end_date = date WHERE end_date IS NULL");
    echo json_encode(["status" => "success", "message" => "تمت إضافة عمود 'end_date' إلى 'atk_holidays' بنجاح."]);
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo json_encode(["status" => "success", "message" => "عمود 'end_date' موجود بالفعل."]);
    } else {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "خطأ في قاعدة البيانات: " . $e->getMessage()]);
    }
}
?>
