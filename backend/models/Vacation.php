<?php
class Vacation
{
    private $conn;
    private $table_name = "atk_vacations";

    public $id, $employee_id, $start_date, $end_date, $total_days, $status, $vacation_type, $attachment, $reason, $is_hourly, $start_time, $end_time, $total_minutes, $notes;

    public function __construct($db)
    {
        $this->conn = $db;
    }

    public function readAll()
    {
        $query = "SELECT v.*, e.name as employee_name FROM " . $this->table_name . " v JOIN atk_employees e ON v.employee_id = e.id ORDER BY v.id DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function create()
    {
        $query = "INSERT INTO " . $this->table_name . " SET employee_id=:emp_id, start_date=:sd, end_date=:ed, total_days=:td, status=:status, vacation_type=:v_type, attachment=:attachment, reason=:reason, is_hourly=:is_h, start_time=:st, end_time=:et, total_minutes=:tm";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":emp_id", $this->employee_id);
        $stmt->bindParam(":sd", $this->start_date);
        $stmt->bindParam(":ed", $this->end_date);
        $stmt->bindParam(":td", $this->total_days);
        $stmt->bindParam(":status", $this->status);
        $stmt->bindParam(":v_type", $this->vacation_type);
        $stmt->bindParam(":attachment", $this->attachment);
        $stmt->bindParam(":reason", $this->reason);

        $is_h = isset($this->is_hourly) ? $this->is_hourly : 0;
        $st = isset($this->start_time) ? $this->start_time : null;
        $et = isset($this->end_time) ? $this->end_time : null;
        $tm = isset($this->total_minutes) ? $this->total_minutes : 0;

        $stmt->bindParam(":is_h", $is_h);
        $stmt->bindParam(":st", $st);
        $stmt->bindParam(":et", $et);
        $stmt->bindParam(":tm", $tm);

        if ($stmt->execute()) {
            if ($this->status == 'approved' && $this->vacation_type == 'إجازة سنوية') {
                $q2 = "UPDATE atk_employees SET vacation_credit = vacation_credit - :tm WHERE id = :emp_id";
                $s2 = $this->conn->prepare($q2);
                $s2->bindParam(":tm", $tm);
                $s2->bindParam(":emp_id", $this->employee_id);
                $s2->execute();
            }
            return true;
        }
        return false;
    }

    public function updateStatus($id, $status, $notes = null)
    {
        // First get the current status
        $q0 = "SELECT status, vacation_type, total_minutes, employee_id FROM " . $this->table_name . " WHERE id = :id";
        $s0 = $this->conn->prepare($q0);
        $s0->bindParam(":id", $id);
        $s0->execute();
        $vacationData = $s0->fetch(PDO::FETCH_ASSOC);

        if (!$vacationData) return false;

        $oldStatus = $vacationData['status'];
        $vacType = $vacationData['vacation_type'];
        $totalMinutes = $vacationData['total_minutes'];
        $empId = $vacationData['employee_id'];

        $query = "UPDATE " . $this->table_name . " SET status=:status, notes=:notes WHERE id=:id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":status", $status);
        $stmt->bindParam(":notes", $notes);
        $stmt->bindParam(":id", $id);
        if ($stmt->execute()) {
            if ($vacType == 'إجازة سنوية') {
                if ($status == 'approved' && $oldStatus != 'approved') {
                    // deduct
                    $q2 = "UPDATE atk_employees SET 
                           vacation_credit = vacation_credit - :tm,
                           monthly_annual_leave_limit_minutes = monthly_annual_leave_limit_minutes - :tm
                           WHERE id = :empId";
                    $s2 = $this->conn->prepare($q2);
                    $s2->bindParam(":tm", $totalMinutes);
                    $s2->bindParam(":empId", $empId);
                    $s2->execute();
                } else if ($oldStatus == 'approved' && $status != 'approved') {
                    // refund
                    $q2 = "UPDATE atk_employees SET 
                           vacation_credit = vacation_credit + :tm,
                           monthly_annual_leave_limit_minutes = monthly_annual_leave_limit_minutes + :tm
                           WHERE id = :empId";
                    $s2 = $this->conn->prepare($q2);
                    $s2->bindParam(":tm", $totalMinutes);
                    $s2->bindParam(":empId", $empId);
                    $s2->execute();
                }
            }
            return true;
        }
        return false;
    }

    public function hasConflictingVacation($employee_id, $start_date, $end_date, $is_hourly = false)
    {
        // Condition for overlap: (StartA <= EndB) AND (EndA >= StartB)
        // If the new request is hourly, it can coexist with other hourly requests, but not with full-day ones.
        if ($is_hourly) {
            $query = "SELECT COUNT(*) FROM " . $this->table_name . " 
                      WHERE employee_id = :emp_id 
                      AND (status = 'approved' OR status = 'pending')
                      AND is_hourly = 0
                      AND start_date <= :ed 
                      AND end_date >= :sd";
        } else {
            $query = "SELECT COUNT(*) FROM " . $this->table_name . " 
                      WHERE employee_id = :emp_id 
                      AND (status = 'approved' OR status = 'pending')
                      AND start_date <= :ed 
                      AND end_date >= :sd";
        }
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":emp_id", $employee_id);
        $stmt->bindParam(":sd", $start_date);
        $stmt->bindParam(":ed", $end_date);
        $stmt->execute();
        return $stmt->fetchColumn() > 0;
    }

    public function getVacationDetails($id)
    {
        $query = "SELECT v.*, e.name as employee_name FROM " . $this->table_name . " v JOIN atk_employees e ON v.employee_id = e.id WHERE v.id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $id);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function getEmployeeName($employee_id)
    {
        $query = "SELECT name FROM atk_employees WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $employee_id);
        $stmt->execute();
        return $stmt->fetchColumn();
    }
    public function deleteVacation($id)
    {
        $q = "SELECT employee_id, start_date, total_minutes, vacation_type, status FROM " . $this->table_name . " WHERE id = :id";
        $stmt = $this->conn->prepare($q);
        $stmt->bindParam(":id", $id);
        $stmt->execute();
        $vacationData = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$vacationData) return ["success" => false, "message" => "الإجازة غير موجودة."];

        $empId = $vacationData['employee_id'];
        $startDate = $vacationData['start_date'];
        $totalMinutes = $vacationData['total_minutes'];
        $vacType = $vacationData['vacation_type'];
        $status = $vacationData['status'];

        $q2 = "SELECT id FROM atk_monthly_payrolls WHERE employee_id = :empId AND start_date <= :sd AND end_date >= :sd";
        $s2 = $this->conn->prepare($q2);
        $s2->bindParam(":empId", $empId);
        $s2->bindParam(":sd", $startDate);
        $s2->execute();
        
        if ($s2->fetch()) {
            return ["success" => false, "message" => "لا يمكن حذف هذه الإجازة لأنها تقع ضمن شهر تم إغلاقه (الإغلاق الشهري)."];
        }

        $q3 = "DELETE FROM " . $this->table_name . " WHERE id = :id";
        $s3 = $this->conn->prepare($q3);
        $s3->bindParam(":id", $id);
        
        if ($s3->execute()) {
            if ($vacType == 'إجازة سنوية' && $status == 'approved') {
                $q4 = "UPDATE atk_employees SET 
                       vacation_credit = vacation_credit + :tm,
                       monthly_annual_leave_limit_minutes = monthly_annual_leave_limit_minutes + :tm
                       WHERE id = :empId";
                $s4 = $this->conn->prepare($q4);
                $s4->bindParam(":tm", $totalMinutes);
                $s4->bindParam(":empId", $empId);
                $s4->execute();
            }
            return ["success" => true, "message" => "تم حذف الإجازة بنجاح."];
        }

        return ["success" => false, "message" => "حدث خطأ أثناء حذف الإجازة."];
    }
}
?>