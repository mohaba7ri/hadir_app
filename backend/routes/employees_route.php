<?php
require_once 'controllers/EmployeeController.php';

$controller = new EmployeeController($db);
$method = $_SERVER['REQUEST_METHOD'];
$controller->processRequest($method, $id);
?>
