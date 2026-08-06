<?php
require_once 'c:/xampp/htdocs/attendace/backend/database/db.php';
$db = (new Database())->getConnection();
$stmt = $db->query("SELECT * FROM atk_settings LIMIT 1");
print_r($stmt->fetch(PDO::FETCH_ASSOC));
