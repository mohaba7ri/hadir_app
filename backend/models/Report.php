<?php
class Report {
    private $conn;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function getAttendanceReport() {
        $query = "SELECT e.name as employee, 
            SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) as present_days,
            SUM(CASE WHEN a.status = 'late' THEN 1 ELSE 0 END) as late_days,
            SUM(CASE WHEN a.status = 'absent' THEN 1 ELSE 0 END) as absent_days
            FROM atk_employees e LEFT JOIN atk_attendance a ON e.id = a.employee_id
            GROUP BY e.id";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function getSalaryReport() {
        $query = "SELECT e.name as employee, e.salary, e.special_start_time, e.special_end_time, e.work_days_per_week,
            SUM(CASE WHEN a.status = 'absent' THEN 1 ELSE 0 END) as absent_days,
            SUM(a.late_minutes) as total_late_minutes,
            SUM(a.early_exit_minutes) as total_early_exit_minutes
            FROM atk_employees e LEFT JOIN atk_attendance a ON e.id = a.employee_id
            GROUP BY e.id";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function getVacationReport() {
        $query = "SELECT name as employee, (30 - vacation_credit) as used_days, vacation_credit as remaining_days FROM atk_employees";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function getLateReport() {
        $query = "SELECT e.name as employee, SUM(a.late_minutes) as total_late_minutes 
            FROM atk_employees e JOIN atk_attendance a ON e.id = a.employee_id
            GROUP BY e.id HAVING total_late_minutes > 0";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function getEmployeeClosings($employee_id) {
        $query = "SELECT id, month, year, start_date, end_date, salary_snapshot, work_days_per_week_snapshot, totals_json, created_at 
                  FROM atk_monthly_payrolls 
                  WHERE employee_id = :employee_id 
                  ORDER BY year DESC, month DESC, start_date DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute([':employee_id' => $employee_id]);
        return $stmt;
    }
}
?>
