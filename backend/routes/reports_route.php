<?php
require_once 'controllers/ReportController.php';

$controller = new ReportController($db);
$method = $_SERVER['REQUEST_METHOD'];
$type = isset($path_parts[$base_index + 2]) ? $path_parts[$base_index + 2] : null;

$controller->processRequest($method, $type);
?>
