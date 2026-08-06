<?php
require_once 'database/db.php';

$database = new Database();
$db = $database->getConnection();

try {
    // 1. Create atk_departments table
    $query1 = "CREATE TABLE IF NOT EXISTS atk_departments (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )";
    $db->exec($query1);
    echo "Table atk_departments created successfully.\n";

    // 2. Add department_id to atk_employees
    $query2 = "ALTER TABLE atk_employees ADD COLUMN department_id INT NULL";
    try {
        $db->exec($query2);
        echo "Column department_id added to atk_employees.\n";
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
            echo "Column department_id already exists in atk_employees.\n";
        } else {
            throw $e;
        }
    }

    // 3. Add foreign key (optional but good practice)
    $query3 = "ALTER TABLE atk_employees ADD CONSTRAINT fk_department FOREIGN KEY (department_id) REFERENCES atk_departments(id) ON DELETE SET NULL";
    try {
        $db->exec($query3);
        echo "Foreign key constraint added.\n";
    } catch (PDOException $e) {
        // Ignore if constraint already exists
    }

    echo "Migration completed successfully.";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>
