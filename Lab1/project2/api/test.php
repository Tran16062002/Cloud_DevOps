<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$response = [
    'status' => 'success',
    'message' => 'Hello from Project 2 API!',
    'timestamp' => time(),
    'data' => [
        'project' => 'Project 2',
        'version' => '1.0',
        'features' => ['HTTPS', 'API', 'PHP Support']
    ]
];

echo json_encode($response, JSON_PRETTY_PRINT);
?>
