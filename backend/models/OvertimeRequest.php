<?php
class OvertimeRequest {
    private $conn;
    private $table_name = "atk_overtime_requests";

    public $id, $employee_id, $employee_name, $date, $start_time, $end_time, $total_minutes, $status, $reason, $admin_note, $created_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function createTable() {
        $query = "CREATE TABLE IF NOT EXISTS " . $this->table_name . " (
            id INT AUTO_INCREMENT PRIMARY KEY,
            employee_id INT NOT NULL,
            date DATE NOT NULL,
            start_time TIME NOT NULL,
            end_time TIME NOT NULL,
            total_minutes INT NOT NULL,
            status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
            reason TEXT,
            admin_note TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (employee_id) REFERENCES atk_employees(id) ON DELETE CASCADE
        )";
        $this->conn->exec($query);
    }

    public function create() {
        $this->createTable();

        // 1. Calculate total minutes
        $start = new DateTime($this->start_time);
        $end = new DateTime($this->end_time);
        $interval = $start->diff($end);
        $this->total_minutes = ($interval->h * 60) + $interval->i;
        if ($end < $start) {
            $this->total_minutes += 24 * 60; // Handle overnight overtime if applicable
        }

        // 2. Insert
        $query = "INSERT INTO " . $this->table_name . " 
                  SET employee_id=:emp_id, date=:date, start_time=:s_time, end_time=:e_time, 
                      total_minutes=:total, status=:status, reason=:reason";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":emp_id", $this->employee_id);
        $stmt->bindParam(":date", $this->date);
        $stmt->bindParam(":s_time", $this->start_time);
        $stmt->bindParam(":e_time", $this->end_time);
        $stmt->bindParam(":total", $this->total_minutes);
        $stmt->bindParam(":status", $this->status);
        $stmt->bindParam(":reason", $this->reason);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function getAllRequests($employee_id = null) {
        $this->createTable();
        $query = "SELECT r.*, e.name as employee_name 
                  FROM " . $this->table_name . " r
                  JOIN atk_employees e ON r.employee_id = e.id";
        
        if ($employee_id != null) {
            $query .= " WHERE r.employee_id = :emp_id";
        }
        
        $query .= " ORDER BY r.date DESC, r.created_at DESC";
        
        $stmt = $this->conn->prepare($query);
        if ($employee_id != null) {
            $stmt->bindParam(":emp_id", $employee_id);
        }
        $stmt->execute();
        return $stmt;
    }

    public function updateStatus($id, $status, $admin_note = "") {
        $query = "UPDATE " . $this->table_name . " 
                  SET status = :status, admin_note = :note 
                  WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":status", $status);
        $stmt->bindParam(":note", $admin_note);
        $stmt->bindParam(":id", $id);
        return $stmt->execute();
    }
}
?>
