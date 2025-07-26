<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$host = 'localhost';
$db   = 'db_crab';
$user = 'crab';
$pass = 'password';

$pdo = new PDO("mysql:host=$host;dbname=$db", $user, $pass);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$deviceID = $_GET['deviceID'] ?? '';

if ($deviceID) {
    $stmt = $pdo->prepare("
        SELECT deviceID, turbidity, temp, ph, oxgen, ec,
               dateCaptured, timeCaptured
        FROM tbl_sensor
        WHERE deviceID = :deviceID
        ORDER BY dateCaptured DESC, timeCaptured DESC
        LIMIT 100
    ");
    $stmt->execute(['deviceID' => $deviceID]);
    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
} else {
    echo json_encode(['error' => 'deviceID required']);
}
?>
