<?php
$ch = curl_init('http://localhost/attendace/backend/attendance/monthly-summary?employee_id=123&month=6&year=2026');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$res = curl_exec($ch);
curl_close($ch);
file_put_contents('scratch_json.json', $res);
