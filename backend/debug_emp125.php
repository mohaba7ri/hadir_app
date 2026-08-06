<?php
require_once __DIR__ . '/database/db.php';
require_once __DIR__ . '/services/AttendanceEngine.php';

// Let's just create a PDO directly to avoid issues.
$host = 'localhost';
$db = 'attendace';
$user = 'root';
$pass = '';

$dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";
$pdo = new PDO($dsn, $user, $pass, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);

$engine = new AttendanceEngine($pdo);

$stmt = $pdo->prepare("SELECT COUNT(*), MIN(date), MAX(date) FROM atk_attendance WHERE employee_id = 125");
$stmt->execute();
print_r($stmt->fetch(PDO::FETCH_ASSOC));

$res = $engine->autoClosePastMonths(125, '2026-08-24');
print_r($res);
