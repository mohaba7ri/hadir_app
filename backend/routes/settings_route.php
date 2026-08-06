<?php
require_once 'controllers/SettingController.php';

$controller = new SettingController($db);
$method = $_SERVER['REQUEST_METHOD'];
$controller->processRequest($method);
?>
