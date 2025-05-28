<?php
// Leer el contenido del archivo de log donde se almacenan los eventos
$log = file('metrics.log');

// Inicializar arrays para almacenar las métricas
$starts = [];       // Contador de inicios de juegos
$maxScores = [];    // Puntuaciones máximas por juego
$sumScores = [];    // Suma total de puntuaciones por juego (para medias)
$countScores = [];  // Número de puntuaciones registradas por juego

foreach ($log as $line) {
    // Buscar eventos de inicio de partida: "- juego - start"
    if (preg_match('/-\s*(\w+)\s*-\s*start/', $line, $matches)) {
        $game = $matches[1];
        $starts[$game] = ($starts[$game] ?? 0) + 1;
    }

    // Buscar eventos de puntuación: "- juego - score - valor"
    if (preg_match('/- ([^-]+) - score - (\d+)/', $line, $matches)) {
        $game = $matches[1];
        $score = intval($matches[2]);

        // Actualizar puntuación máxima
        $maxScores[$game] = max($maxScores[$game] ?? 0, $score);

        // Acumular puntuaciones y contar partidas puntuadas
        $sumScores[$game] = ($sumScores[$game] ?? 0) + $score;
        $countScores[$game] = ($countScores[$game] ?? 0) + 1;
    }
}

// Leer likes y dislikes
$likesLog = file('metrics_likes.log');
$likes = [];
$dislikes = [];

foreach ($likesLog as $line) {
    // Buscar eventos de likes y dislikes: 
    // "- juego - like" 
    if (preg_match('/-\s*(\w+)\s*-\s*like/', $line, $matches)) {
        $game = $matches[1];
        $likes[$game] = ($likes[$game] ?? 0) + 1;
    }

    // "- juego - dislike"
    if (preg_match('/-\s*(\w+)\s*-\s*dislike/', $line, $matches)) {
        $game = $matches[1];
        $dislikes[$game] = ($dislikes[$game] ?? 0) + 1;
    }
}

// Salida en formato Prometheus
header('Content-Type: text/plain');

// Métricas de partidas iniciadas
foreach ($starts as $game => $count) {
    echo "game_starts_total{game=\"$game\"} $count\n";
}

// Métricas de puntuación máxima
foreach ($maxScores as $game => $max) {
    echo "game_max_score{game=\"$game\"} $max\n";
}

// Métricas de puntuación media
foreach ($sumScores as $game => $sum) {
    $avg = $sum / ($countScores[$game] ?? 1);
    echo "game_avg_score{game=\"$game\"} $avg\n";
}

// Likes
foreach ($likes as $game => $count) {
    echo "game_likes_total{game=\"$game\"} $count\n";
}

// Dislikes
foreach ($dislikes as $game => $count) {
    echo "game_dislikes_total{game=\"$game\"} $count\n";
}



?>
