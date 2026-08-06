<?php
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    // Block native mobile app logins based on Dart User-Agent
    $userAgent = $_SERVER['HTTP_USER_AGENT'] ?? '';
    if (strpos($userAgent, 'Dart') !== false) {
        http_response_code(403);
        echo json_encode(["message" => "التطبيق متوقف حالياً. يرجى تسجيل الدخول عبر الموقع الإلكتروني:\nhttps://hadir.gheta-alrahmah.com/"]);
        exit();
    }

    $data = json_decode(file_get_contents("php://input"));

    $identifier = $data->identifier ?? '';
    $password = $data->password ?? '';

    if (empty($identifier) || empty($password)) {
        http_response_code(400);
        echo json_encode(["message" => "يرجى تقديم كل من المعرف وكلمة المرور."]);
        exit();
    }

    // Admin login check from Database
    $stmt = $db->prepare("SELECT role, password, full_name FROM atk_admins WHERE username = ?");
    $stmt->execute([$identifier]);
    $admin_data = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($admin_data) {
        if ($password === $admin_data['password']) {
            echo json_encode([
                "status" => "success",
                "isAdmin" => true,
                "isSuperAdmin" => ($admin_data['role'] === 'super_admin'),
                "token" => "admin_session_token",
                "identifier" => $identifier,
                "name" => $admin_data['full_name'] ?? 'المدير'
            ]);
        } else {
            http_response_code(401);
            echo json_encode(["message" => "بيانات الاعتماد غير صالحة لـ $identifier."]);
        }
    }
    // Employee login check (assuming identifier is numeric)
    else {
        require_once 'models/Employee.php';
        $employee = new Employee($db);

        // Try searching by ID
        $emp_data = $employee->readOne($identifier);

        if ($emp_data && $emp_data['password'] === $password) {
            echo json_encode([
                "status" => "success",
                "isAdmin" => false,
                "employee" => [
                    "id" => $emp_data['id'],
                    "name" => $emp_data['name']
                ],
                "token" => "employee_session_token_" . $emp_data['id']
            ]);
        } else {
            http_response_code(401);
            echo json_encode(["message" => "رقم الهوية أو كلمة المرور غير صحيحة."]);
        }
    }
} else if ($method === 'PUT') {
    $data = json_decode(file_get_contents("php://input"));
    $identifier = $data->identifier ?? '';
    $old_password = $data->old_password ?? '';
    $new_password = $data->new_password ?? '';

    if (empty($identifier) || empty($old_password) || empty($new_password)) {
        http_response_code(400);
        echo json_encode(["message" => "بيانات مفقودة."]);
        exit();
    }

    // Admin password update
    $stmt = $db->prepare("SELECT password FROM atk_admins WHERE username = ?");
    $stmt->execute([$identifier]);
    $admin_data = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($admin_data) {
        if ($old_password === $admin_data['password']) {
            $updateStmt = $db->prepare("UPDATE atk_admins SET password = ? WHERE username = ?");
            if ($updateStmt->execute([$new_password, $identifier])) {
                echo json_encode(["status" => "success", "message" => "تم تحديث كلمة المرور."]);
            } else {
                http_response_code(500);
                echo json_encode(["message" => "فشل تحديث كلمة المرور."]);
            }
        } else {
            http_response_code(401);
            echo json_encode(["message" => "كلمة المرور القديمة غير صحيحة."]);
        }
    } else {
        require_once 'models/Employee.php';
        $employee = new Employee($db);
        $emp_data = $employee->readOne($identifier);

        if ($emp_data && $emp_data['password'] === $old_password) {
            // Update the password - requires Employee model to handle only password update or generic update
            // Reusing existing model structure
            $employee->id = $emp_data['id'];
            $employee->name = $emp_data['name']; // Keep current
            $employee->password = $new_password;
            if ($employee->update()) {
                echo json_encode(["status" => "success", "message" => "تم تحديث كلمة المرور."]);
            } else {
                http_response_code(500);
                echo json_encode(["message" => "فشل التحديث."]);
            }
        } else {
            http_response_code(401);
            echo json_encode(["message" => "كلمة المرور القديمة غير صحيحة."]);
        }
    }
}
?>