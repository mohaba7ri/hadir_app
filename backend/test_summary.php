<?php
require_once 'c:/xampp/htdocs/attendace/backend/database/db.php';
require_once 'c:/xampp/htdocs/attendace/backend/services/AttendanceEngine.php';
$db = (new Database())->getConnection();
$engine = new AttendanceEngine($db);
$res = $engine->getMonthlySummary(125, 10, 2025);
echo json_encode($res, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
