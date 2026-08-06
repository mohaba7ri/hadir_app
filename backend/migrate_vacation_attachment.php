<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

try {
    // Add attachment column to atk_vacations
    $db->exec("ALTER TABLE atk_vacations ADD COLUMN attachment VARCHAR(255) DEFAULT NULL AFTER vacation_type");
    echo "Successfully added attachment column to atk_vacations table.\n";
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo "Column 'attachment' already exists in atk_vacations.\n";
    } else {
        echo "Error updating atk_vacations: " . $e->getMessage() . "\n";
    }
}
?>
