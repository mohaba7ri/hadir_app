<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

try {
    $db->exec("UPDATE atk_settings SET min_version = 10, force_update_url = 'https://hadir.gheta-alrahmah.com/'");
    echo "Force update settings applied successfully.\n";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
