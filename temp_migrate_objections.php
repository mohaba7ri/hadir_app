<?php
require_once 'backend/database/db.php';
$db = (new Database())->getConnection();
try {
    $db->exec("ALTER TABLE atk_objections ADD COLUMN vacation_type VARCHAR(100) DEFAULT NULL");
    $db->exec("ALTER TABLE atk_objections ADD COLUMN attachment VARCHAR(255) DEFAULT NULL");
    echo "Columns added successfully.\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
