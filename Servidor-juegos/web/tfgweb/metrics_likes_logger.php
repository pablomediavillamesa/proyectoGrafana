<?php
$game = $_GET['game'] ?? 'unknown';
$event = $_GET['event'] ?? 'unknown';
$timestamp = date('c');

// Registrar evento en metrics_likes.log
file_put_contents('metrics_likes.log', "$timestamp - $game - $event\n", FILE_APPEND);
?>
