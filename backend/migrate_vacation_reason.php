<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

try {
    $db->exec("ALTER TABLE atk_vacations ADD COLUMN reason TEXT AFTER vacation_type");
    echo "Successfully added reason column to atk_vacations.";
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo "Column 'reason' already exists.";
    } else {
        echo "Error: " . $e->getMessage();
    }
}
?>
