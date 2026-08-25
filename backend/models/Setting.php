<?php
class Setting {
    private $conn;
    private $table_name = "atk_settings";

    public $id, $default_start_time, $allowed_late_minutes, $ramadan_start_time, $ramadan_end_time, $ramadan_mode, $default_end_time, $last_renewal_year, $min_version, $force_update_url, $auto_monthly_payroll_enabled, $last_auto_closing_month;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function getSettings() {
        $query = "SELECT * FROM " . $this->table_name . " LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function update() {
        $query = "UPDATE " . $this->table_name . " SET 
            default_start_time=:dst, 
            allowed_late_minutes=:alm, 
            ramadan_start_time=:rst, 
            ramadan_end_time=:ret, 
            ramadan_mode=:rm,
            default_end_time=:det,
            last_renewal_year=:lry,
            min_version=:mv,
            force_update_url=:fuu,
            auto_monthly_payroll_enabled=:ampe,
            last_auto_closing_month=:lacm
            WHERE id=:id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":dst", $this->default_start_time);
        $stmt->bindParam(":alm", $this->allowed_late_minutes);
        $stmt->bindParam(":rst", $this->ramadan_start_time);
        $stmt->bindParam(":ret", $this->ramadan_end_time);
        $stmt->bindParam(":rm", $this->ramadan_mode);
        $stmt->bindParam(":det", $this->default_end_time);
        $stmt->bindParam(":lry", $this->last_renewal_year);
        $stmt->bindParam(":mv", $this->min_version);
        $stmt->bindParam(":fuu", $this->force_update_url);
        $stmt->bindParam(":ampe", $this->auto_monthly_payroll_enabled);
        $stmt->bindParam(":lacm", $this->last_auto_closing_month);
        $stmt->bindParam(":id", $this->id);
        return $stmt->execute();
    }

    public function updateLastAutoClosingMonth($monthStr) {
        $query = "UPDATE " . $this->table_name . " SET last_auto_closing_month = :lacm WHERE id = 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":lacm", $monthStr);
        return $stmt->execute();
    }
}
?>
