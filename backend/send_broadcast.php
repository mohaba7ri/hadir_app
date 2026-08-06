<?php
/**
 * Broadcast Notification Script
 * This script allows an admin to send a notification to all users.
 * Specifically used for forced updates.
 */

require_once 'database/db.php';

require_once 'fcm_v1_helper.php';

// In a real app, this should be protected by admin authentication
$fcm = new FCMHelper(__DIR__ . '/hadir-app-d5cfb-762235c5666e.json');

/**
 * Sends a Broadcast FCM message using V1
 */
function sendBroadcastFCM($topic, $title, $body, $updateUrl = null) {
    global $fcm;
    
    $extraData = [
        'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
    ];
    
    if ($updateUrl) {
        $extraData['force_update_url'] = $updateUrl;
    }
    
    return $fcm->sendToTopic($topic, $title, $body, $extraData);
}

// Example usage via CLI or direct GET/POST
if (php_sapi_name() === 'cli') {
    // If running from command line, use arguments
    $title = $argv[1] ?? 'تحديث هام للمنظومة';
    $message = $argv[2] ?? 'يجب عليك تحديث التطبيق الآن لضمان استمرارية الخدمة.';
    $url = $argv[3] ?? 'https://drive.google.com/your-update-link';
    
    echo "Sending broadcast to 'all_users'...\n";
    $res = sendBroadcastFCM('all_users', $title, $message, $url);
    echo "Result: " . json_encode($res, JSON_PRETTY_PRINT) . "\n";
} else {
    // If running via URL, check for parameters
    $title = $_GET['title'] ?? 'تحديث هام للمنظومة';
    $message = $_GET['message'] ?? 'يجب عليك تحديث التطبيق الآن لضمان استمرارية الخدمة.';
    $url = $_GET['url'] ?? null;

    if (!$url) {
        echo json_encode(["status" => "error", "message" => "معلمة الرابط مطلوبة."]);
        exit;
    }

    $res = sendBroadcastFCM('all_users', $title, $message, $url);
    header('Content-Type: application/json');
    echo json_encode($res);
}
?>
