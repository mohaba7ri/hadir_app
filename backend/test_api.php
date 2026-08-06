<?php
$ch = curl_init('http://localhost/attendace/backend/reports/split-payroll');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['employee_id'=>125, 'month'=>8, 'year'=>2026, 'end_date'=>'2026-08-24']));
$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
echo "HTTP: $http_code\n";
echo "Response: $response\n";

$ch2 = curl_init('http://localhost/attendace/backend/reports/split-payroll');
curl_setopt($ch2, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch2, CURLOPT_POST, true);
curl_setopt($ch2, CURLOPT_POSTFIELDS, json_encode(['employee_id'=>202, 'month'=>8, 'year'=>2026, 'end_date'=>'2026-08-24']));
$response2 = curl_exec($ch2);
$http_code2 = curl_getinfo($ch2, CURLINFO_HTTP_CODE);
echo "HTTP 2: $http_code2\n";
echo "Response 2: $response2\n";
