<?php
require_once 'backend/database/db.php';
$db = (new Database())->getConnection();
$stmt = $db->query("SELECT id, name, special_start_time, special_end_time FROM atk_employees WHERE id IN (104, 121, 124, 102)");
$emps = $stmt->fetchAll(PDO::FETCH_ASSOC);
print_r($emps);
