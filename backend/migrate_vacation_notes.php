<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

try {
    $query = "ALTER TABLE atk_vacations ADD COLUMN notes TEXT NULL";
    $db->exec($query);
    echo json_encode(["status" => "success", "message" => "Success: notes column added to atk_vacations"]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
