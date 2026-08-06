<?php
class Holiday {
    private $conn;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function getHolidays() {
        $query = "SELECT * FROM atk_holidays ORDER BY date DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function getWeeklyHolidays() {
        $query = "SELECT * FROM atk_weekly_holidays";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function createHoliday($name, $date, $end_date = null, $is_recurring = 0) {
        if ($end_date === null) $end_date = $date;
        $query = "INSERT INTO atk_holidays SET name=:name, date=:date, end_date=:end_date, is_recurring=:is_recurring";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":name", $name);
        $stmt->bindParam(":date", $date);
        $stmt->bindParam(":end_date", $end_date);
        $stmt->bindParam(":is_recurring", $is_recurring);
        return $stmt->execute();
    }

    public function deleteHoliday($id) {
        $query = "DELETE FROM atk_holidays WHERE id=:id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $id);
        return $stmt->execute();
    }

    public function updateWeeklyHolidays($days) {
        $this->conn->exec("DELETE FROM atk_weekly_holidays");
        $query = "INSERT INTO atk_weekly_holidays (day_name) VALUES (:day)";
        $stmt = $this->conn->prepare($query);
        foreach($days as $day) {
            $stmt->bindParam(":day", $day);
            $stmt->execute();
        }
        return true;
    }
}
?>
