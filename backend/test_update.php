<?php
require_once 'database/db.php';
require_once 'models/Employee.php';
$database = new Database();
$db = $database->getConnection();
$employee = new Employee($db);

$id = 125; // As per the user's report
$employee->id = $id;
$employee->name = "Test Update";
$employee->salary = 1000;
$employee->special_start_time = null;
$employee->special_end_time = null;
$employee->vacation_credit = 30;
$employee->status = 'inactive';

try {
    if ($employee->update()) {
        echo "Update successful!";
    } else {
        echo "Update failed (no error thrown).";
    }
} catch (Exception $e) {
    echo "Update threw exception: " . $e->getMessage();
}
