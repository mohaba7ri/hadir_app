<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

try {
    $db->exec("ALTER TABLE atk_attendance ADD COLUMN early_exit_minutes INT DEFAULT 0 AFTER late_minutes");
    echo json_encode(["status" => "success", "message" => "تمت إضافة عمود early_exit_minutes."]);
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
