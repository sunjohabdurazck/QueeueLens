<?php
require __DIR__ . '/../config/firebase.php';

$docs = $firestore->collection('users')->limit(1)->documents();

foreach ($docs as $doc) {
    echo "OK: " . $doc->id();
}
