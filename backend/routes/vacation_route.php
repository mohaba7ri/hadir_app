<?php
require_once 'controllers/VacationController.php';

$controller = new VacationController($db);
$method = $_SERVER['REQUEST_METHOD'];
$controller->processRequest($method, $id);
?>
