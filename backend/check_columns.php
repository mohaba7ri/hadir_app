<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

try {
    $stmt = $db->query("DESCRIBE atk_employees");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    header("Content-Type: application/json");
    echo json_encode(["status" => "success", "columns" => $columns]);
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
