<?php
/**
 * FCM Diagnostic Script
 * Use this to test if notifications reach your device.
 */

require_once 'fcm_v1_helper.php';

$fcm = new FCMHelper(__DIR__ . '/hadir-app-d5cfb-762235c5666e.json');

$id = $_GET['id'] ?? null;
$topic = $id ? "employee_$id" : "all_users";

echo "<h2>FCM Diagnostic Tool</h2>";
echo "Targeting topic: <b>$topic</b><br><br>";

try {
    $result = $fcm->sendToTopic($topic, "اختبار نظام حاضر 🔔", "هذا إشعار تجريبي للتأكد من وصول التنبيهات خارج التطبيق.", [
        'test_data' => 'true',
        'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
    ]);

    echo "<b>Response from Firebase:</b><br>";
    echo "<pre>" . json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "</pre>";

    if ($result['status'] === 'success') {
        echo "<br><span style='color:green'>✅ Success! If you don't see the notification on your phone, check:</span>";
        echo "<ul>
                <li>Is your phone's 'google-services.json' from the same project?</li>
                <li>Are notifications enabled for the app in Android Settings?</li>
                <li>Is battery saver or 'Do Not Disturb' mode ON?</li>
              </ul>";
    } else {
        echo "<br><span style='color:red'>❌ Error! Firebase rejected the request. Check your service account JSON.</span>";
    }

} catch (Exception $e) {
    echo "<br><span style='color:red'>❌ Exception: " . $e->getMessage() . "</span>";
}
?>
