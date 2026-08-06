<?php
$f = fopen('c:\\xampp\\htdocs\\attendace\\backend\\database\\atten.jsonl', 'r');
if (!$f) {
    echo "Could not open file\n";
    exit;
}
$count = 0;
while ($line = fgets($f)) {
    $data = json_decode($line, true);
    if (isset($data['user_days'])) {
        foreach ($data['user_days'] as $key => $day) {
            if (isset($day['user_id']) && $day['user_id'] == '123' && isset($day['date']) && strpos($day['date'], '2026-06') === 0) {
                echo 'Found: ' . $day['date'] . ' -> First: ' . $day['first'] . ' Last: ' . $day['last'] . PHP_EOL;
                $count++;
            }
        }
    }
}
fclose($f);
echo "Total found: $count\n";
