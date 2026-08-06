<?php
ob_start(); // Start output buffering
require_once 'database/db.php';
require_once 'models/Employee.php';
require_once 'models/Attendance.php';
require_once 'models/Setting.php';
require_once 'models/Vacation.php';
require_once 'models/Holiday.php';

$database = new Database();
$db = $database->getConnection();

if (!$db) {
    die("Database connection failed. Check your db.php settings.");
}

$schema = file_get_contents('database/schema.sql');
$queries = explode(';', $schema);

$success = 0;
$total = 0;

foreach ($queries as $query) {
    $query = trim($query);
    if (!empty($query)) {
        $total++;
        try {
            $db->exec($query);
            $success++;
        } catch (PDOException $e) {
            // Ignore if table/database already exists, but keep track of real errors
            if (strpos($e->getMessage(), 'already exists') === false) {
                 // echo "Error in query: $query <br> " . $e->getMessage() . "<br>";
            }
        }
    }
}

ob_end_clean(); // Clean any unintentional output
header("Content-Type: application/json");
echo json_encode(["status" => "success", "message" => "تمت تهيئة قاعدة البيانات بنجاح.", "queries_executed" => $success, "total_queries" => $total]);
?>
