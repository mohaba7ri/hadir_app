<?php
require_once 'controllers/HolidayController.php';

$controller = new HolidayController($db);
$method = $_SERVER['REQUEST_METHOD'];

$type = isset($path_parts[$base_index + 2]) && $path_parts[$base_index + 2] == 'weekly' ? 'weekly' : 'general';
$id = isset($path_parts[$base_index + 3]) ? $path_parts[$base_index + 3] : null;
if ($type === 'general' && isset($path_parts[$base_index + 2])) {
    $id = $path_parts[$base_index + 2];
}

$controller->processRequest($method, $type, $id);
?>
