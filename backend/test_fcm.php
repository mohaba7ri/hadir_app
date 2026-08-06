<?php
// /tmp/test_fcm.php
$server_key = 'AIzaSyBn--fpRxlsyc3zd4VtvZFZI-XrY-Irkpw';
$token = 'fsqxW5zXQ6yw7X4xwqQ1vZ:APA91bEhFXGl-6G0NFsy1T5_sZBADy-DK-xfw6zVCBz1BnelPf1LdDERhIHIInG79w5hN9EycicxGNMTjlD-phbiHqV1dnXy51l9aMYUo0gMgybWm8aNbU8';
$title = 'Direct Test';
$body = 'This is a test to a specific token';

$url = 'https://fcm.googleapis.com/fcm/send';
$fields = array(
    'to' => $token,
    'notification' => array(
        'title' => $title, 
        'body' => $body, 
        'sound' => 'default',
        'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
    )
);
$headers = array(
    'Authorization: key=' . $server_key,
    'Content-Type: application/json'
);

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
$result = curl_exec($ch);
$info = curl_getinfo($ch);
$error = curl_error($ch);
curl_close($ch);

echo "HTTP Code: " . $info['http_code'] . "\n";
echo "Response: " . $result . "\n";
echo "CURL Error: " . $error . "\n";
?>
