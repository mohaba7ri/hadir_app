<?php
require_once 'controllers/AttendanceCorrectionsController.php';

$controller = new AttendanceCorrectionsController($db);
$method = $_SERVER['REQUEST_METHOD'];
$controller->processRequest($method, $id);
?>
