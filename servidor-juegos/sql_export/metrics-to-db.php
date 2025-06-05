<?php

$now = date('Y-m-d H:i:s');
echo "==== INICIO EJECUCIÓN METRICS-TO-DB.PHP: $now ====\n";


// Configuración de conexión a la base MySQL
$host = '172.20.2.10'; // Cambia por la IP de tu servidor
$db = 'monitoring';     // Nombre de la base de datos
$user = 'pablom';       // Usuario con permisos
$pass = 'pablom';       // Contraseña del usuario
$dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";

try {
    $pdo = new PDO($dsn, $user, $pass);
    echo "Conexión a MySQL exitosa.\n";
} catch (PDOException $e) {
    die("Error de conexión: " . $e->getMessage() . "\n");
}


// Rutas absolutas de los archivos log
$log_path = "/var/www/tfgweb/"; // Cambiar a la ruta real
$filename_metrics = $log_path . "metrics.log";
$filename_likes = $log_path . "metrics_likes.log";

$inserted_metrics = 0;
$inserted_likes = 0;

// === Procesar metrics.log ===
if (file_exists($filename_metrics)) {
    $file = fopen($filename_metrics, "r");
    while (($line = fgets($file)) !== false) {
        $line = trim($line);
        if (empty($line)) continue;

        // Separar por " - " (guion con espacios)
        $parts = explode(' - ', $line);

        // Deben existir al menos 3 partes (fecha, juego, evento)
        if (count($parts) < 3) {
            echo "Línea inválida en metrics: $line\n";
            continue;
        }

        // Normalizar fecha/hora
        try {
            $dt = new DateTime($parts[0]);
            $event_time = $dt->format('Y-m-d H:i:s');
        } catch (Exception $e) {
            echo "Formato inválido en metrics: {$parts[0]}\n";
            continue;
        }

        $game = $parts[1];
        $event_type = $parts[2];
        $score = (isset($parts[3]) && is_numeric($parts[3])) ? intval($parts[3]) : null;

        // Si es start, score debe ser NULL
        if ($event_type === 'start') {
            $score = null;
        }

        // Evitar duplicados
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM metrics WHERE event_time = ? AND game = ? AND event_type = ?");
        $stmt->execute([$event_time, $game, $event_type]);
        if ($stmt->fetchColumn() == 0) {
            $insert = $pdo->prepare("INSERT INTO metrics (event_time, game, event_type, score) VALUES (?, ?, ?, ?)");
            $insert->execute([$event_time, $game, $event_type, $score]);
            //echo "Insertado en metrics: $event_time $game $event_type " . ($score ?? 'NULL') . "\n";
		$inserted_metrics++;

	}
    }
    fclose($file);
} else {
    echo "Archivo no encontrado: $filename_metrics\n";
}

// === Procesar metrics_likes.log ===
if (file_exists($filename_likes)) {
    $file = fopen($filename_likes, "r");
    while (($line = fgets($file)) !== false) {
        $line = trim($line);
        if (empty($line)) continue;

        // Separar por " - " (guion con espacios)
        $parts = explode(' - ', $line);

        // Deben existir al menos 3 partes (fecha, juego, reacción)
        if (count($parts) < 3) {
            echo "Línea inválida en metrics_likes: $line\n";
            continue;
        }

        // Normalizar fecha/hora
        try {
            $dt = new DateTime($parts[0]);
            $event_time = $dt->format('Y-m-d H:i:s');
        } catch (Exception $e) {
            echo "Formato inválido en metrics_likes: {$parts[0]}\n";
            continue;
        }

        $game = $parts[1];
        $reaction_type = $parts[2];

        // Evitar duplicados
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM metrics_likes WHERE event_time = ? AND game = ? AND reaction_type = ?");
        $stmt->execute([$event_time, $game, $reaction_type]);
        if ($stmt->fetchColumn() == 0) {
            $insert = $pdo->prepare("INSERT INTO metrics_likes (event_time, game, reaction_type) VALUES (?, ?, ?)");
            $insert->execute([$event_time, $game, $reaction_type]);
            //echo "Insertado en metrics_likes: $event_time $game $reaction_type\n";
        	$inserted_likes++;
	}
    }
    fclose($file);
} else {
    echo "Archivo no encontrado: $filename_likes\n";
}

echo "Nuevos registros insertados en metrics: $inserted_metrics\n";
echo "Nuevos registros insertados en metrics_likes: $inserted_likes\n";
echo "Inserción completa.\n";
$now = date('Y-m-d H:i:s');
echo "==== FIN EJECUCIÓN METRICS-TO-DB.PHP: $now ====\n";

?>
