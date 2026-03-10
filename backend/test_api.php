<?php

$url = 'http://127.0.0.1:8000/api/patrol-tokens';
$data = ['area' => 'Area Smoking'];

$options = [
    'http' => [
        'header' => "Content-type: application/json\r\n" .
            "Accept: application/json\r\n" .
            "X-Device-Key: STEeZY_SECRET_2026\r\n",
        'method' => 'POST',
        'content' => json_encode($data),
        'ignore_errors' => true // To read body on 4xx/5xx responses
    ]
];

$context = stream_context_create($options);
echo "Sending POST request to $url...\n";
$result = file_get_contents($url, false, $context);

echo "Response Headers:\n";
var_dump($http_response_header[0]);
echo "\nResponse Body:\n";
echo $result . "\n";
