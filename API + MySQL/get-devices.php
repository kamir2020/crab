<?php
$host = 'localhost';
$db   = 'db_crab';
$user = 'crab';
$pass = 'password';

$pdo = new PDO("mysql:host=$host;dbname=$db", $user, $pass);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$sql = "
SELECT s.deviceID, d.deviceName,d.deviceLocation,
       s.turbidity, s.temp, s.ph, s.oxgen, s.ec,
       s.dateCaptured, s.timeCaptured,
       CONCAT(s.dateCaptured, ' ', s.timeCaptured) AS last_updated
FROM tbl_sensor s
JOIN (
    SELECT deviceID, MAX(CONCAT(dateCaptured, ' ', timeCaptured)) as max_datetime
    FROM tbl_sensor
    GROUP BY deviceID
) latest ON CONCAT(s.dateCaptured, ' ', s.timeCaptured) = latest.max_datetime AND s.deviceID = latest.deviceID
JOIN tbl_device d ON s.deviceID = d.deviceID
ORDER BY s.deviceID
";

$stmt = $pdo->query($sql);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$now = new DateTime();
foreach ($rows as &$row) {
    $lastUpdated = DateTime::createFromFormat('Y-m-d H:i:s', $row['last_updated']);
    if (!$lastUpdated) {
        $row['status'] = 'Unknown';
    } else {
        $diff = $now->getTimestamp() - $lastUpdated->getTimestamp();
        $row['status'] = ($diff > 86400) ? 'Offline' : 'Online'; // 86400 = 24*60*60
    }
    unset($row['last_updated']); // remove helper field
}

header('Content-Type: application/json');
echo json_encode($rows);
?>
