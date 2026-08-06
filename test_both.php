<?php
require_once __DIR__ . '/backend/database/db.php';
$dbCls = new Database();
$dbCls->debugMode = false;
$db = $dbCls->getConnection();
$stmt = $db->query("SELECT * FROM atk_attendance WHERE late_minutes > 0 AND early_exit_minutes > 0 LIMIT 5");
$res = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode($res, JSON_PRETTY_PRINT);
?>
