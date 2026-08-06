<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

try {
    $db->exec("ALTER TABLE atk_vacations ADD COLUMN vacation_type VARCHAR(255) DEFAULT 'إجازة سنوية' AFTER total_days");
    echo "Successfully added vacation_type column.";
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo "Column already exists.";
    } else {
        echo "Error: " . $e->getMessage();
    }
}
?>
