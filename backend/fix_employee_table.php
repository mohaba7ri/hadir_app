<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

try {
    $db->exec("ALTER TABLE atk_employees ADD COLUMN position VARCHAR(255) AFTER name");
    echo "Successfully added position column.";
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo "Column already exists.";
    } else {
        echo "Error: " . $e->getMessage();
    }
}
?>
