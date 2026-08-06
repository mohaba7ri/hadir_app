<?php
require_once 'controllers/AttendanceController.php';

$controller = new AttendanceController($db);
$method = $_SERVER['REQUEST_METHOD'];

$action = isset($path_parts[$base_index + 2]) ? $path_parts[$base_index + 2] : null;

$controller->processRequest($method, $id, $action);
?>
