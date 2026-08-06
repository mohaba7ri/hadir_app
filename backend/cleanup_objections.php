<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

try {
    $db->exec("DROP TABLE IF EXISTS atk_objections");
    echo json_encode(["status" => "success", "message" => "تم حذف الجدول الملغى 'atk_objections' بنجاح."]);
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
