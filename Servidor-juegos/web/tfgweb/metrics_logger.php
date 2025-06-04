<?php
$game = $_GET['game'] ?? 'unknown';   // Captura el nombre del juego
$event = $_GET['event'] ?? 'unknown'; // Captura el evento
$score = $_GET['score'] ?? null;      // Captura la puntuación (si existe)
$timestamp = date('c');               // Formato ISO8601 para la hora

// Registrar eventos de inicio (start)
if ($event == 'start') {
    file_put_contents('metrics.log', "$timestamp - $game - start\n", FILE_APPEND);
}

// Registrar eventos de puntuación (score) en minúscula
if ($event == 'score') {
    file_put_contents('metrics.log', "$timestamp - $game - score - $score\n", FILE_APPEND);
}
?>
