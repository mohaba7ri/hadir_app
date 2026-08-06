<?php
require_once 'database/db.php';
$database = new Database();
$db = $database->getConnection();

try {
    echo "Dropping (if corrupted) and recreating atk_settings...\n";
    $db->exec("DROP TABLE IF EXISTS atk_settings");
    $db->exec("CREATE TABLE atk_settings (
        id INT AUTO_INCREMENT PRIMARY KEY,
        default_start_time TIME DEFAULT '08:00:00',
        allowed_late_minutes INT DEFAULT 15,
        ramadan_start_time TIME DEFAULT '10:00:00',
        ramadan_end_time TIME DEFAULT '15:00:00',
        ramadan_mode BOOLEAN DEFAULT FALSE,
        default_end_time TIME DEFAULT '16:00:00',
        last_renewal_year INT DEFAULT 2026,
        min_version INT DEFAULT 1,
        force_update_url TEXT NULL
    )");
    
    $db->exec("INSERT INTO atk_settings (default_start_time, allowed_late_minutes, ramadan_start_time, ramadan_end_time, ramadan_mode, default_end_time, min_version) 
               VALUES ('08:00:00', 15, '10:00:00', '15:00:00', 0, '16:00:00', 1)");
    
    echo "Table atk_settings recreated successfully.\n";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
