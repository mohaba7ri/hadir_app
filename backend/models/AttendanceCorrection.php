<?php
class AttendanceCorrection
{
    private $conn;
    private $table_name = "atk_attendance_corrections";

    public $id;
    public $employee_id;
    public $date;
    public $type;
    public $original_time;
    public $requested_time;
    public $reason;
    public $status;
    public $admin_note;
    public $created_at;
    public $approved_by;

    public function __construct($db)
    {
        $this->conn = $db;
    }

    public function create()
    {
        $query = "INSERT INTO " . $this->table_name . "
                (employee_id, date, type, original_time, requested_time, reason, status)
                VALUES (:employee_id, :date, :type, :original_time, :requested_time, :reason, :status)";

        $stmt = $this->conn->prepare($query);

        if (empty($this->status)) {
            $this->status = 'pending';
        }

        $stmt->bindParam(':employee_id', $this->employee_id);
        $stmt->bindParam(':date', $this->date);
        $stmt->bindParam(':type', $this->type);
        $stmt->bindParam(':original_time', $this->original_time);
        $stmt->bindParam(':requested_time', $this->requested_time);
        $stmt->bindParam(':reason', $this->reason);
        $stmt->bindParam(':status', $this->status);

        $success = $stmt->execute();

        if ($success && $this->status === 'approved') {
            $lastId = $this->conn->lastInsertId();
            $this->applyToAttendance($lastId);
        }

        return $success;
    }

    public function getAll($employee_id = null)
    {
        $query = "SELECT c.*, e.name as employee_name 
                 FROM " . $this->table_name . " c
                 JOIN atk_employees e ON c.employee_id = e.id ";

        if ($employee_id) {
            $query .= " WHERE c.employee_id = :emp_id";
        }
        $query .= " ORDER BY c.created_at DESC";

        $stmt = $this->conn->prepare($query);
        if ($employee_id) {
            $stmt->bindParam(':emp_id', $employee_id);
        }
        $stmt->execute();
        return $stmt;
    }

    public function updateStatus($id, $status, $admin_note, $admin_id)
    {
        $query = "UPDATE " . $this->table_name . "
                SET status = :status, admin_note = :note, approved_by = :admin_id
                WHERE id = :id";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':status', $status);
        $stmt->bindParam(':note', $admin_note);
        $stmt->bindParam(':admin_id', $admin_id);
        $stmt->bindParam(':id', $id);

        $success = $stmt->execute();

        if ($success && $status === 'approved') {
            $this->applyToAttendance($id);
        }

        return $success;
    }

    private function applyToAttendance($correction_id)
    {
        $q = "SELECT employee_id, date, type, requested_time FROM " . $this->table_name . " WHERE id = :id";
        $st = $this->conn->prepare($q);
        $st->bindParam(':id', $correction_id);
        $st->execute();
        $corr = $st->fetch(PDO::FETCH_ASSOC);

        if (!$corr)
            return;

        $empId = $corr['employee_id'];
        $date = $corr['date'];
        $type = $corr['type'];
        $reqTime = $corr['requested_time'];

        $qEmp = "SELECT id, special_start_time, special_end_time, is_flexible, required_hours FROM atk_employees WHERE id = :id";
        $stEmp = $this->conn->prepare($qEmp);
        $stEmp->bindParam(':id', $empId);
        $stEmp->execute();
        $empInfo = $stEmp->fetch(PDO::FETCH_ASSOC);

        if (!$empInfo)
            return;

        $qSett = "SELECT * FROM atk_settings LIMIT 1";
        $stSett = $this->conn->prepare($qSett);
        $stSett->execute();
        $settings = $stSett->fetch(PDO::FETCH_ASSOC);

        $default_start = $settings['default_start_time'] ?? '08:00:00';
        $default_end = $settings['default_end_time'] ?? '16:00:00';
        $allowed_late = $settings['allowed_late_minutes'] ?? 15;
        if (isset($settings['ramadan_mode']) && $settings['ramadan_mode'] == 1) {
            $default_start = $settings['ramadan_start_time'] ?? '10:00:00';
            $default_end = $settings['ramadan_end_time'] ?? '15:00:00';
        }

        $qAtt = "SELECT * FROM atk_attendance WHERE employee_id = :emp_id AND date = :date";
        $stAtt = $this->conn->prepare($qAtt);
        $stAtt->bindParam(':emp_id', $empId);
        $stAtt->bindParam(':date', $date);
        $stAtt->execute();
        $att = $stAtt->fetch(PDO::FETCH_ASSOC);

        $checkIn = $att ? $att['check_in'] : null;
        $checkOut = $att ? $att['check_out'] : null;

        if ($type === 'check_in' || $type === 'missing_check_in') {
            $checkIn = $date . ' ' . $reqTime;
        } else if ($type === 'check_out' || $type === 'missing_check_out') {
            $checkOut = $date . ' ' . $reqTime;
        }

        $late_minutes = 0;
        $early_exit_minutes = 0;

        $isFlex = $empInfo['is_flexible'] ?? 0;
        $reqHours = $empInfo['required_hours'] ?? 8.00;

        if ($isFlex) {
            if ($checkOut && $checkIn) {
                $durationMins = (strtotime($checkOut) - strtotime($checkIn)) / 60;
                $reqMins = $reqHours * 60;
                if ($durationMins < $reqMins) {
                    $early_exit_minutes = floor($reqMins - $durationMins);
                }
            }
        } else {
            $work_start_special = $empInfo['special_start_time'];
            $work_end_special = $empInfo['special_end_time'];

            $late_mins_special = 0;
            $early_exit_mins_special = 0;
            $hasSpecial = !empty($work_start_special) && !empty($work_end_special);

            if ($hasSpecial && $checkIn) {
                $expected_special = date('Y-m-d H:i:s', strtotime($date . ' ' . $work_start_special));
                if (strtotime($checkIn) > strtotime($expected_special)) {
                    $late_mins_special = floor((strtotime($checkIn) - strtotime($expected_special)) / 60);
                }
                if ($checkOut) {
                    $expectedOut_special = date('Y-m-d H:i:s', strtotime($date . ' ' . $work_end_special));
                    if (strtotime($work_end_special) < strtotime($work_start_special)) {
                        $expectedOut_special = date('Y-m-d H:i:s', strtotime($date . ' ' . $work_end_special . ' +1 day'));
                    }
                    if (strtotime($checkOut) < strtotime($expectedOut_special)) {
                        $early_exit_mins_special = floor((strtotime($expectedOut_special) - strtotime($checkOut)) / 60);
                    }
                }
            }

            $late_mins_default = 0;
            $early_exit_mins_default = 0;

            if ($checkIn) {
                $expected_default = date('Y-m-d H:i:s', strtotime($date . ' ' . $default_start));
                if (strtotime($checkIn) > strtotime($expected_default)) {
                    $late_mins_default = floor((strtotime($checkIn) - strtotime($expected_default)) / 60);
                }
            }
            if ($checkOut) {
                $expectedOut_default = date('Y-m-d H:i:s', strtotime($date . ' ' . $default_end));
                if (strtotime($default_end) < strtotime($default_start)) {
                    $expectedOut_default = date('Y-m-d H:i:s', strtotime($date . ' ' . $default_end . ' +1 day'));
                }
                if (strtotime($checkOut) < strtotime($expectedOut_default)) {
                    $early_exit_mins_default = floor((strtotime($expectedOut_default) - strtotime($checkOut)) / 60);
                }
            }

            if ($hasSpecial) {
                if (($late_mins_default + $early_exit_mins_default) <= ($late_mins_special + $early_exit_mins_special)) {
                    $late_minutes = $late_mins_default;
                    $early_exit_minutes = $early_exit_mins_default;
                } else {
                    $late_minutes = $late_mins_special;
                    $early_exit_minutes = $early_exit_mins_special;
                }
            } else {
                $late_minutes = $late_mins_default;
                $early_exit_minutes = $early_exit_mins_default;
            }
        }

        $status = 'present';
        if ($isFlex) {
            if ($early_exit_minutes > 0)
                $status = 'early_exit';
        } else {
            if ($late_minutes > $allowed_late)
                $status = 'late';
        }

        if (!$checkOut || !$checkIn) {
            $status = 'incomplete';
        }

        if ($att) {
            $qUp = "UPDATE atk_attendance SET check_in = :check_in, check_out = :check_out, late_minutes = :late, early_exit_minutes = :early, status = :status WHERE id = :id";
            $stUp = $this->conn->prepare($qUp);
            $stUp->bindParam(':check_in', $checkIn);
            $stUp->bindParam(':check_out', $checkOut);
            $stUp->bindParam(':late', $late_minutes);
            $stUp->bindParam(':early', $early_exit_minutes);
            $stUp->bindParam(':status', $status);
            $stUp->bindParam(':id', $att['id']);
            $stUp->execute();
        } else {
            $qIns = "INSERT INTO atk_attendance (employee_id, date, check_in, check_out, late_minutes, early_exit_minutes, status, source) VALUES (:emp_id, :date, :check_in, :check_out, :late, :early, :status, 'correction')";
            $stIns = $this->conn->prepare($qIns);
            $stIns->bindParam(':emp_id', $empId);
            $stIns->bindParam(':date', $date);
            $stIns->bindParam(':check_in', $checkIn);
            $stIns->bindParam(':check_out', $checkOut);
            $stIns->bindParam(':late', $late_minutes);
            $stIns->bindParam(':early', $early_exit_minutes);
            $stIns->bindParam(':status', $status);
            $stIns->execute();
        }
    }

    public function getPendingCountForDate($emp_id, $date)
    {
        $query = "SELECT COUNT(*) as count FROM " . $this->table_name . " 
                  WHERE employee_id = :emp_id AND date = :date AND status = 'pending'";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':emp_id', $emp_id);
        $stmt->bindParam(':date', $date);
        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row['count'] ?? 0;
    }
}
?>