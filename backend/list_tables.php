<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

$tables = [];
$stmt = $db->query("SHOW TABLES");
while ($row = $stmt->fetch(PDO::FETCH_NUM)) {
    $tables[] = $row[0];
}

header("Content-Type: application/json");
echo json_encode(["status" => "success", "tables" => $tables]);
?>
