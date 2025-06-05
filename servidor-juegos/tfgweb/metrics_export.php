<?php
$log = file('metrics.log');
$likesLog = file('metrics_likes.log');

$starts = [];
$maxScores = [];
$sumScores = [];
$countScores = [];
$lastScore = [];
$seenScores = [];  // Guardar puntuaciones vistas para evitar duplicados
$likes = [];
$dislikes = [];

// Procesar cada línea del log
foreach ($log as $line) {
    if (preg_match('/-\s*(\w+)\s*-\s*start/', $line, $matches)) {
        $game = $matches[1];
        $starts[$game] = ($starts[$game] ?? 0) + 1;
    }
    if (preg_match('/- ([^-]+) - score - (\d+)/', $line, $matches)) {
        $game = $matches[1];
        $score = intval($matches[2]);

        // Evitar duplicados de puntuaciones (registro único por juego + puntuación)
        $scoreKey = "$game-$score";
        if (isset($seenScores[$scoreKey])) {
            continue;  // Saltar si ya hemos procesado este score
        }
        $seenScores[$scoreKey] = true;

        $maxScores[$game] = max($maxScores[$game] ?? 0, $score);
        $sumScores[$game] = ($sumScores[$game] ?? 0) + $score;
        $countScores[$game] = ($countScores[$game] ?? 0) + 1;
        $lastScore[$game] = $score; // Actualizar última puntuación
    }
}

// Procesar likes y dislikes
foreach ($likesLog as $line) {
    if (preg_match('/-\s*(\w+)\s*-\s*like/', $line, $matches)) {
        $game = $matches[1];
        $likes[$game] = ($likes[$game] ?? 0) + 1;
    }
    if (preg_match('/-\s*(\w+)\s*-\s*dislike/', $line, $matches)) {
        $game = $matches[1];
        $dislikes[$game] = ($dislikes[$game] ?? 0) + 1;
    }
}

header('Content-Type: text/plain');

foreach ($starts as $game => $count) {
    echo "game_starts_total{game=\"$game\"} $count\n";
}
foreach ($maxScores as $game => $max) {
    echo "game_max_score{game=\"$game\"} $max\n";
}
foreach ($sumScores as $game => $sum) {
    $avg = $sum / ($countScores[$game] ?? 1);
    echo "game_avg_score{game=\"$game\"} $avg\n";
}
foreach ($lastScore as $game => $score) {
    echo "game_last_score{game=\"$game\"} $score\n";
	if ($score >= ($maxScores[$game] ?? 0)) {
	    echo "new_record{game=\"$game\"} $score\n";
	} else {
	    echo "new_record{game=\"$game\"} 0\n";
	}
}

// Exportar likes y dislikes
foreach ($likes as $game => $count) {
    echo "game_likes_total{game=\"$game\"} $count\n";
}
foreach ($dislikes as $game => $count) {
    echo "game_dislikes_total{game=\"$game\"} $count\n";
}
?>
