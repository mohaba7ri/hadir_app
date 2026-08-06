<?php
require_once 'database/db.php';
require_once 'models/Vacation.php';

$database = new Database();
$db = $database->getConnection();
$vacation = new Vacation($db);

$vacation->employee_id = 1; // Assuming employee 1 exists
$vacation->start_date = '2026-04-01';
$vacation->end_date = '2026-04-05';
$vacation->total_days = 5;
$vacation->vacation_type = 'إجازة سنوية';
$vacation->status = 'pending';

try {
    if ($vacation->create()) {
        echo "Vacation created successfully!";
    } else {
        echo "Failed to create vacation.";
    }
} catch (PDOException $e) {
    echo "Database Error: " . $e->getMessage();
} catch (Exception $e) {
    echo "General Error: " . $e->getMessage();
}
?>
