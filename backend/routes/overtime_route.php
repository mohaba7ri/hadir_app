<?php
require_once 'controllers/OvertimeController.php';

$controller = new OvertimeController($db);
$method = $_SERVER['REQUEST_METHOD'];
$controller->processRequest($method, $id);
?>
