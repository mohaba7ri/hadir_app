<?php
class Employee {
    private $conn;
    private $table_name = "atk_employees";

    public $id, $name, $salary, $special_start_time, $special_end_time, $vacation_credit, $work_days_per_week, $status, $password, $is_flexible, $required_hours, $department_id, $monthly_annual_leave_limit_minutes;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function readAll($department_id = null) {
        // ... (Renewal and Self-healing logic same as before)
        $currentYear = date('Y');
        try {
            $q = "SELECT last_renewal_year FROM atk_settings LIMIT 1";
            $s = $this->conn->prepare($q);
            $s->execute();
            $storedYear = $s->fetchColumn();

            if ($storedYear && $currentYear > $storedYear) {
                $resetQuery = "UPDATE " . $this->table_name . " SET vacation_credit = 30";
                $this->conn->prepare($resetQuery)->execute();
                $updateYear = "UPDATE atk_settings SET last_renewal_year = :year";
                $stmtYear = $this->conn->prepare($updateYear);
                $stmtYear->bindParam(":year", $currentYear);
                $stmtYear->execute();
            }
            try {
                $this->conn->query("SELECT password FROM " . $this->table_name . " LIMIT 1");
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'Unknown column') !== false) {
                    $this->conn->exec("ALTER TABLE " . $this->table_name . " ADD COLUMN password VARCHAR(255) DEFAULT '123'");
                }
            }
            try {
                $this->conn->query("SELECT department_id FROM " . $this->table_name . " LIMIT 1");
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'Unknown column') !== false) {
                    $this->conn->exec("ALTER TABLE " . $this->table_name . " ADD COLUMN department_id INT NULL");
                }
            }
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'Unknown column') !== false) {
                $this->conn->exec("ALTER TABLE atk_settings ADD COLUMN last_renewal_year INT DEFAULT 2026");
            }
        }

        $query = "SELECT e.*, d.name as department_name 
                  FROM " . $this->table_name . " e
                  LEFT JOIN atk_departments d ON e.department_id = d.id";
        
        if ($department_id !== null) {
            $query .= " WHERE e.department_id = :dept_id";
        }

        $stmt = $this->conn->prepare($query);
        if ($department_id !== null) {
            $stmt->bindParam(":dept_id", $department_id);
        }
        $stmt->execute();
        return $stmt;
    }

    public function readOne($id) {
        $query = "SELECT e.*, d.name as department_name 
                  FROM " . $this->table_name . " e
                  LEFT JOIN atk_departments d ON e.department_id = d.id
                  WHERE e.id = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->execute([$id]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . " SET id=:id, name=:name, salary=:salary, special_start_time=:s_time, special_end_time=:e_time, vacation_credit=:vac, work_days_per_week=:wd, status=:status, password=:pass, is_flexible=:flex, required_hours=:req, department_id=:dept_id, monthly_annual_leave_limit_minutes=:limit_mins";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":salary", $this->salary);
        $stmt->bindParam(":s_time", $this->special_start_time);
        $stmt->bindParam(":e_time", $this->special_end_time);
        $stmt->bindParam(":vac", $this->vacation_credit);
        $stmt->bindParam(":wd", $this->work_days_per_week);
        $stmt->bindParam(":status", $this->status);
        $stmt->bindParam(":pass", $this->password);
        $stmt->bindParam(":flex", $this->is_flexible);
        $stmt->bindParam(":req", $this->required_hours);
        $stmt->bindParam(":dept_id", $this->department_id);
        $stmt->bindParam(":limit_mins", $this->monthly_annual_leave_limit_minutes);
        return $stmt->execute();
    }

    public function update() {
        $query = "UPDATE " . $this->table_name . " SET name=:name, salary=:salary, special_start_time=:s_time, special_end_time=:e_time, vacation_credit=:vac, work_days_per_week=:wd, status=:status, password=:pass, is_flexible=:flex, required_hours=:req, department_id=:dept_id, monthly_annual_leave_limit_minutes=:limit_mins WHERE id=:id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":salary", $this->salary);
        $stmt->bindParam(":s_time", $this->special_start_time);
        $stmt->bindParam(":e_time", $this->special_end_time);
        $stmt->bindParam(":vac", $this->vacation_credit);
        $stmt->bindParam(":wd", $this->work_days_per_week);
        $stmt->bindParam(":status", $this->status);
        $stmt->bindParam(":pass", $this->password);
        $stmt->bindParam(":flex", $this->is_flexible);
        $stmt->bindParam(":req", $this->required_hours);
        $stmt->bindParam(":dept_id", $this->department_id);
        $stmt->bindParam(":limit_mins", $this->monthly_annual_leave_limit_minutes);
        $stmt->bindParam(":id", $this->id);
        return $stmt->execute();
    }

    public function delete() {
        $query = "DELETE FROM " . $this->table_name . " WHERE id=:id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $this->id);
        return $stmt->execute();
    }
}
?>
