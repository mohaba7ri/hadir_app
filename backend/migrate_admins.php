<?php
require_once 'database/db.php';

$database = new Database();
$db = $database->getConnection();

try {
    // Create atk_admins table
    $sql = "CREATE TABLE IF NOT EXISTS atk_admins (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(255) NOT NULL UNIQUE,
        full_name VARCHAR(255) DEFAULT '',
        password VARCHAR(255) NOT NULL,
        role ENUM('admin', 'super_admin') DEFAULT 'admin',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )";
    $db->exec($sql);
    
    try {
        $db->exec("ALTER TABLE atk_admins ADD COLUMN full_name VARCHAR(255) DEFAULT ''");
    } catch (PDOException $e) {
        // Ignore duplicate column error
    }
    echo "Table atk_admins ensured with full_name column.\n";

    // Insert admin
    $stmt = $db->prepare("INSERT INTO atk_admins (username, password, role, full_name) VALUES (?, ?, ?, ?)");
    
    // Check if admin exists
    $check = $db->prepare("SELECT id FROM atk_admins WHERE username = ?");
    
    // admin
    $check->execute(['admin']);
    if (!$check->fetch()) {
        $stmt->execute(['admin', '123', 'admin', 'المدير العام']);
        echo "Admin user created successfully.\n";
    } else {
        $upd = $db->prepare("UPDATE atk_admins SET full_name = ? WHERE username = ?");
        $upd->execute(['المدير العام', 'admin']);
        echo "Admin user updated with full name.\n";
    }
    
    // super_admin
    $check->execute(['super_admin']);
    if (!$check->fetch()) {
        $stmt->execute(['super_admin', 'admin', 'super_admin', 'المسؤول المتميز']);
        echo "Super Admin user created successfully.\n";
    } else {
        $upd = $db->prepare("UPDATE atk_admins SET full_name = ? WHERE username = ?");
        $upd->execute(['المسؤول المتميز', 'super_admin']);
        echo "Super Admin user updated with full name.\n";
    }
    
    // moha
    $check->execute(['moha']);
    if (!$check->fetch()) {
        $stmt->execute(['moha', '730010012', 'admin', 'المهندس محمد']);
        echo "Moha user created successfully.\n";
    } else {
        $upd = $db->prepare("UPDATE atk_admins SET full_name = ? WHERE username = ?");
        $upd->execute(['المهندس محمد', 'moha']);
        echo "Moha user updated with full name.\n";
    }
    
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
