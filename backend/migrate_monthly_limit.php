<?php
require_once __DIR__ . '/database/db.php';

$database = new Database();
$conn = $database->getConnection();

try {
    $conn->exec("ALTER TABLE atk_employees ADD COLUMN monthly_annual_leave_limit_minutes INT DEFAULT 750");
    echo "Successfully added monthly_annual_leave_limit_minutes to atk_employees.\n";
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo "Column monthly_annual_leave_limit_minutes already exists.\n";
    } else {
        echo "Error: " . $e->getMessage() . "\n";
    }
}
?>
