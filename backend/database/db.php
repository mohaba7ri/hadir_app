<?php
// backend/database/db.php
// Headers are handled in index.php

class Database
{
    public $debugMode = true; // Set to true for local, false for production

    private $host = "localhost";

    // Local DB credentials
    private $local_db_name = "\tattendance";
    private $local_username = "root";
    private $local_password = "";

    // Production DB credentials
    private $prod_db_name = "u526405128_hadir";
    private $prod_username = "u526405128_hadir";
    private $prod_password = "7nzVwvNG4_sQs&6";

    public $conn;

    public function getConnection()
    {
        $this->conn = null;

        $db_name = $this->debugMode ? $this->local_db_name : $this->prod_db_name;
        $username = $this->debugMode ? $this->local_username : $this->prod_username;
        $password = $this->debugMode ? $this->local_password : $this->prod_password;

        try {
            $this->conn = new PDO("mysql:host=" . $this->host . ";dbname=" . $db_name . ";charset=utf8", $username, $password);
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $exception) {
            http_response_code(500);
            if (ob_get_length())
                ob_clean();
            echo json_encode(["status" => "error", "message" => "خطأ في قاعدة البيانات: " . $exception->getMessage()]);
            exit;
        }
        return $this->conn;
    }
}
?>