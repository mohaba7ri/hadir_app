<?php
class Attendance {
    private $conn;
    private $table_name = "atk_attendance";

    public $id, $employee_id, $date, $check_in, $check_out, $late_minutes, $early_exit_minutes, $status, $source;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function readAll() {
        $query = "SELECT a.*, e.name as employee_name, e.salary, e.special_start_time, e.special_end_time, e.is_flexible, e.required_hours, e.work_days_per_week,
                  (SELECT SUM(total_minutes) FROM atk_vacations v 
                   WHERE v.employee_id = a.employee_id AND v.status = 'approved' AND v.is_hourly = 1 AND v.start_date = a.date AND v.reason LIKE '%[COVER_LATE]%') as approved_hourly_late,
                  (SELECT SUM(total_minutes) FROM atk_vacations v 
                   WHERE v.employee_id = a.employee_id AND v.status = 'approved' AND v.is_hourly = 1 AND v.start_date = a.date AND v.reason LIKE '%[COVER_EARLY]%') as approved_hourly_early,
                  (SELECT SUM(total_minutes) FROM atk_vacations v 
                   WHERE v.employee_id = a.employee_id AND v.status = 'approved' AND v.is_hourly = 1 AND v.start_date = a.date AND (v.reason IS NULL OR (v.reason NOT LIKE '%[COVER_LATE]%' AND v.reason NOT LIKE '%[COVER_EARLY]%'))) as approved_hourly_both,
                  (SELECT SUM(total_minutes) FROM atk_vacations v 
                   WHERE v.employee_id = a.employee_id AND v.status = 'approved' AND v.is_hourly = 0 AND a.date BETWEEN v.start_date AND v.end_date) as is_full_vacation,
                  (SELECT SUM(total_minutes) FROM atk_overtime_requests o 
                   WHERE o.employee_id = a.employee_id AND o.date = a.date AND o.status = 'approved') as approved_overtime
                  FROM " . $this->table_name . " a 
                  LEFT JOIN atk_employees e ON a.employee_id = e.id 
                  ORDER BY a.date DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . " SET employee_id=:emp_id, date=:b_date, check_in=:check_in, check_out=:check_out, late_minutes=:late, early_exit_minutes=:early, status=:status, source=:source";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":emp_id", $this->employee_id);
        $stmt->bindParam(":b_date", $this->date);
        $stmt->bindParam(":check_in", $this->check_in);
        $stmt->bindParam(":check_out", $this->check_out);
        $stmt->bindParam(":late", $this->late_minutes);
        $stmt->bindParam(":early", $this->early_exit_minutes);
        $stmt->bindParam(":status", $this->status);
        $stmt->bindParam(":source", $this->source);
        
        try {
            return $stmt->execute();
        } catch(PDOException $e) {
            return false;
        }
    }
}
?>
