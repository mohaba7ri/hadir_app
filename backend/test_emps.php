<?php
require_once 'c:/xampp/htdocs/attendace/backend/database/db.php';
$db = (new Database())->getConnection();
$stmt = $db->query("SELECT id, name, special_start_time, special_end_time, required_hours, is_flexible FROM atk_employees WHERE special_start_time IS NOT NULL OR is_flexible = 1 LIMIT 10");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
