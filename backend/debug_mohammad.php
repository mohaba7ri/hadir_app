<?php
require_once __DIR__ . '/database/db.php';
$host = 'localhost'; $db = 'attendace'; $user = 'root'; $pass = '';
$pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass, [PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);

$stmt = $pdo->query("SELECT id, name FROM atk_employees WHERE name LIKE '%محمد%' LIMIT 5");
$emps = $stmt->fetchAll();
print_r($emps);

foreach($emps as $emp) {
    $stmt = $pdo->prepare("SELECT COUNT(*) as cnt, MIN(date) as min_d FROM atk_attendance WHERE employee_id = ?");
    $stmt->execute([$emp['id']]);
    $res = $stmt->fetch();
    echo "Emp {$emp['id']} ({$emp['name']}): {$res['cnt']} records, starting {$res['min_d']}\n";
}
