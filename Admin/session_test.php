<?php
session_start();
$_SESSION['x'] = ($_SESSION['x'] ?? 0) + 1;
echo "session x=" . $_SESSION['x'];
