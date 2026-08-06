<?php
require_once 'models/Setting.php';

class SettingController {
    private $db;
    private $setting;

    public function __construct($db) {
        $this->db = $db;
        $this->setting = new Setting($db);
    }

    public function processRequest($method) {
        switch ($method) {
            case 'GET':
                echo json_encode($this->setting->getSettings());
                break;
            case 'PUT':
                $data = json_decode(file_get_contents("php://input"));
                $this->setting->id = 1;
                $this->setting->default_start_time = $data->default_start_time;
                $this->setting->allowed_late_minutes = $data->allowed_late_minutes;
                $this->setting->ramadan_start_time = $data->ramadan_start_time;
                $this->setting->ramadan_end_time = $data->ramadan_end_time;
                $this->setting->ramadan_mode = $data->ramadan_mode;
                $this->setting->default_end_time = $data->default_end_time;
                $this->setting->last_renewal_year = $data->last_renewal_year ?? 2026;
                $this->setting->min_version = $data->min_version ?? 1;
                $this->setting->force_update_url = $data->force_update_url ?? null;

                if ($this->setting->update()) {
                    http_response_code(200);
                    echo json_encode(["message" => "تم تحديث الإعدادات."]);
                } else {
                    http_response_code(503);
                    echo json_encode(["message" => "تعذر تحديث الإعدادات."]);
                }
                break;
            default:
                http_response_code(405);
                echo json_encode(["message" => "الطريقة غير مسموح بها"]);
        }
    }
}
?>
