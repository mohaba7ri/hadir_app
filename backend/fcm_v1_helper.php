<?php
/**
 * FCM HTTP v1 Helper for PHP (no external dependencies)
 */

class FCMHelper {
    private $serviceAccountFile;
    private $accessToken;
    private $expiry;

    public function __construct($jsonPath) {
        $this->serviceAccountFile = $jsonPath;
    }

    private function getAccessToken() {
        // Simple caching in memory for the current request
        if ($this->accessToken && time() < $this->expiry) {
            return $this->accessToken;
        }

        if (!file_exists($this->serviceAccountFile)) {
            throw new Exception("Service account file not found.");
        }

        $serviceAccount = json_decode(file_get_contents($this->serviceAccountFile), true);
        
        $header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
        $now = time();
        $payload = json_encode([
            'iss' => $serviceAccount['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => $serviceAccount['token_uri'],
            'iat' => $now,
            'exp' => $now + 3600
        ]);
        
        $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
        $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
        
        $signature = '';
        if (!openssl_sign($base64UrlHeader . "." . $base64UrlPayload, $signature, $serviceAccount['private_key'], 'SHA256')) {
            throw new Exception("Failed to sign JWT with OpenSSL.");
        }
        $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
        
        $jwt = $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;

        $options = [
            'http' => [
                'method' => 'POST',
                'header' => 'Content-Type: application/x-www-form-urlencoded',
                'content' => http_build_query([
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion' => $jwt
                ]),
                'ignore_errors' => true
            ]
        ];
        
        $context = stream_context_create($options);
        $result = file_get_contents($serviceAccount['token_uri'], false, $context);
        $data = json_decode($result, true);

        if (isset($data['access_token'])) {
            $this->accessToken = $data['access_token'];
            $this->expiry = $now + $data['expires_in'] - 60;
            return $this->accessToken;
        } else {
            throw new Exception("Failed to get access token: " . ($data['error_description'] ?? $result));
        }
    }

    public function sendToTopic($topic, $title, $body, $data = []) {
        return $this->send(['topic' => $topic], $title, $body, $data);
    }

    public function sendToToken($token, $title, $body, $data = []) {
        return $this->send(['token' => $token], $title, $body, $data);
    }

    private function send($target, $title, $body, $extraData = []) {
        // NOTIFICATIONS DISABLED
        return [
            'status' => 'success',
            'http_code' => 200,
            'response' => 'Notifications disabled.'
        ];

        $serviceAccount = json_decode(file_get_contents($this->serviceAccountFile), true);
        $projectId = $serviceAccount['project_id'];
        $url = "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";

        // Build FCM V1 Message
        $message = $target; // Includes 'topic' or 'token'
        $message['notification'] = [
            'title' => $title,
            'body' => $body
        ];
        
        // Android specific config for high priority
        $message['android'] = [
            'priority' => 'high',
            'notification' => [
                'sound' => 'default',
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
            ]
        ];

        // Merge extra data (must be strings in FCM V1)
        $msgData = [];
        foreach ($extraData as $k => $v) {
            $msgData[$k] = (string)$v;
        }
        if (!empty($msgData)) {
            $message['data'] = $msgData;
        }

        $payload = json_encode(['message' => $message]);
        
        $headers = [
            'Authorization: Bearer ' . $this->getAccessToken(),
            'Content-Type: application/json'
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
        
        $result = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        return [
            'status' => $httpCode == 200 ? 'success' : 'error',
            'http_code' => $httpCode,
            'response' => json_decode($result, true) ?? $result
        ];
    }
}
?>
