<?php
require_once 'database/db.php';

$database = new Database();
$db = $database->getConnection();

try {
    $db->exec("ALTER TABLE atk_settings ADD COLUMN last_renewal_year INT DEFAULT 2026");
    echo "Added last_renewal_year to atk_settings\n";
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo "Column already exists.\n";
    } else {
        echo "Error: " . $e->getMessage() . "\n";
    }
}
?>
