<?php
require_once 'database/db.php';

$database = new Database();
$db = $database->getConnection();

try {
    // Add password column to atk_employees if it doesn't exist
    $db->exec("ALTER TABLE atk_employees ADD COLUMN password VARCHAR(255) DEFAULT '123'");
    echo "Added password column to atk_employees\n";
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo "Password column already exists.\n";
    } else {
        echo "Error adding column: " . $e->getMessage() . "\n";
    }
}

try {
    // Also ensuring admin exists in a settings or dedicated table if needed, 
    // but the user wants simple username/password 'admin/123'.
    // We can handle this logic in the Auth controller directly for simplicity 
    // since it's a hardcoded requirement.
    echo "Migration complete.\n";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
