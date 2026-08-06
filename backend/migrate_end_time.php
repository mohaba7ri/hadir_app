<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

try {
    $db->exec("ALTER TABLE atk_settings ADD COLUMN IF NOT EXISTS default_end_time TIME DEFAULT '16:00:00'");
    $db->exec("ALTER TABLE atk_employees ADD COLUMN IF NOT EXISTS special_end_time TIME NULL AFTER special_start_time");
    
    header("Content-Type: application/json");
    echo json_encode(["status" => "success", "message" => "تم تحديث مخطط قاعدة البيانات لأوقات الانتهاء."]);
} catch (PDOException $e) {
    header("Content-Type: application/json");
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
