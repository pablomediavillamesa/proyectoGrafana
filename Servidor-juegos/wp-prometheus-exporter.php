<?php
/*
Plugin Name: WP Prometheus Exporter
Description: Exporta métricas básicas de WordPress en formato Prometheus.
Version: 1.0
Autor: Pablo Mediavilla
*/

// Requiere autoload de Composer (debes ejecutar 'composer require jimdo/prometheus_client_php')
require_once __DIR__ . '/vendor/autoload.php';

// Importar las clases necesarias del cliente Prometheus
use Prometheus\CollectorRegistry;
use Prometheus\Storage\InMemory;
use Prometheus\RenderTextFormat;

// Inicializar el almacenamiento en memoria (no persistente, ideal para pruebas)
$adapter = new InMemory();
$registry = new CollectorRegistry($adapter);

// Hook 'init' para registrar métricas estáticas (usuarios y publicaciones) una vez al inicio
add_action('init', function () use ($registry) {
    // Obtener el total de usuarios registrados en WordPress
    $user_count = count_users();
    $gauge_users = $registry->getOrRegisterGauge('wp', 'users_total', 'Usuarios registrados');
    $gauge_users->set($user_count['total_users']);

    // Obtener el total de entradas publicadas
    $post_count = wp_count_posts()->publish;
    $gauge_posts = $registry->getOrRegisterGauge('wp', 'posts_published_total', 'Entradas publicadas');
    $gauge_posts->set($post_count);
});

// Hook 'wp_head' para contar visitas y páginas vistas cada vez que se carga una página
add_action('wp_head', function () use ($registry) {
    // Contador total de visitas (simulado)
    $counter_visitas = $registry->getOrRegisterCounter('wp', 'visits_total', 'Visitas al sitio');
    $counter_visitas->inc();

    // Contador de páginas vistas por usuarios (simulado)
    $counter_paginas = $registry->getOrRegisterCounter('wp', 'user_pageviews_total', 'Páginas vistas por los usuarios');
    $counter_paginas->inc();
});

// Crear un endpoint accesible en /?metrics que expone todas las métricas en formato Prometheus
add_action('init', function () use ($registry) {
    if (isset($_GET['metrics'])) {
        // Establecer tipo de contenido
        header('Content-Type: ' . RenderTextFormat::MIME_TYPE);

        // Renderizar y mostrar las métricas
        $renderer = new RenderTextFormat();
        echo $renderer->render($registry->getMetricFamilySamples());
        exit;
    }
});
