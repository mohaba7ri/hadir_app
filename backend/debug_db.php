<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

$result = [];
$tables = ['atk_employees', 'atk_vacations', 'atk_attendance', 'atk_settings'];

foreach ($tables as $table) {
    try {
        $stmt = $db->query("DESCRIBE $table");
        $result[$table] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (Exception $e) {
        $result[$table] = "Error: " . $e->getMessage();
    }
}

header("Content-Type: application/json");
echo json_encode($result, JSON_PRETTY_PRINT);
