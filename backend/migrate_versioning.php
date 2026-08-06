<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

try {
    $db->exec("ALTER TABLE atk_settings ADD COLUMN min_version INT DEFAULT 1");
    $db->exec("ALTER TABLE atk_settings ADD COLUMN force_update_url TEXT NULL");
    echo "Migration successful: Added min_version and force_update_url to atk_settings.\n";
} catch (PDOException $e) {
    echo "Migration might have already run or failed: " . $e->getMessage() . "\n";
}
?>
