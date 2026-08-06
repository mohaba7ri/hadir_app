<?php
require 'database/db.php';
$content = file_get_contents('database/atten.jsonl');
$blocks = preg_split('/}\s*\n\s*{/', $content);

$unique_dates = [];
$unique_pairs = [];
$total_pulses = 0;
$skipped_blocks = 0;

foreach ($blocks as $block) {
    if (substr(trim($block), 0, 1) !== '{') $block = '{' . $block;
    if (substr(trim($block), -1) !== '}') $block = $block . '}';
    
    $data = json_decode($block, true);
    if (!$data || !isset($data['users'])) {
        $skipped_blocks++;
        continue;
    }

    foreach ($data['users'] as $uid => $rec) {
        if (isset($rec['first'])) {
            $total_pulses++;
            $date = date('Y-m-d', strtotime($rec['first']));
            $unique_dates[$date] = 1;
            $unique_pairs[$uid . '_' . $date] = 1;
        }
    }
}

echo "Total JSON Blocks: " . count($blocks) . "\n";
echo "Skipped Blocks: $skipped_blocks\n";
echo "Total Pulses: $total_pulses\n";
echo "Unique Dates: " . count($unique_dates) . "\n";
echo "Unique (User, Date) pairs: " . count($unique_pairs) . "\n";
?>
