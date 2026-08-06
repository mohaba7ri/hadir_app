<?php
$data = json_decode(file_get_contents('scratch_json.json'), true);
if (isset($data['totals'])) {
    print_r($data['totals']);
} else {
    echo "No totals\n";
}
if (isset($data['days'])) {
    foreach ($data['days'] as $day) {
        if ($day['late_discount'] > 0) {
            echo "Date: {$day['date']} Late Disc: {$day['late_discount']}\n";
        }
    }
} else {
    echo "No days\n";
}
