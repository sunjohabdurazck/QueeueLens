<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once 'config/config.php';
requireRole(ROLE_STAFF);

$pageTitle = 'Dashboard';
include 'includes/header.php';

// Include REST API instead of Firebase SDK
require_once 'config/firestore_rest.php';

// Initialize dashboard stats with defaults
$totalServices = 0;
$openServices = 0;
$totalPending = 0;
$totalActive = 0;
$totalServed = 0;
$totalCameras = 0;
$onlineCameras = 0;
$services = [];
$cameras = [];

// Get real-time stats using REST API
try {
    // Get services
    $servicesQuery = [
        "from" => [["collectionId" => "services"]],
        "select" => [
            "fields" => [
                ["fieldPath" => "name"],
                ["fieldPath" => "isOpen"],
                ["fieldPath" => "pendingCount"],
                ["fieldPath" => "activeCount"],
                ["fieldPath" => "totalServed"]
            ]
        ]
    ];
    
    $servicesResults = firestore_runQuery('services', $servicesQuery);
    
    // Process services results
    foreach ($servicesResults as $row) {
        if (!empty($row['document'])) {
            $doc = $row['document'];
            $fields = $doc['fields'] ?? [];
            
            // Convert Firestore fields to simple values
            $serviceData = [];
            foreach ($fields as $k => $v) {
                if (isset($v['stringValue'])) $serviceData[$k] = $v['stringValue'];
                else if (isset($v['booleanValue'])) $serviceData[$k] = (bool)$v['booleanValue'];
                else if (isset($v['integerValue'])) $serviceData[$k] = (int)$v['integerValue'];
                else if (isset($v['doubleValue'])) $serviceData[$k] = (float)$v['doubleValue'];
                else $serviceData[$k] = $v;
            }
            
            $serviceData['_id'] = basename($doc['name']);
            $services[] = $serviceData;
            
            $totalServices++;
            if ($serviceData['isOpen'] ?? false) $openServices++;
            $totalPending += $serviceData['pendingCount'] ?? 0;
            $totalActive += $serviceData['activeCount'] ?? 0;
            $totalServed += $serviceData['totalServed'] ?? 0;
        }
    }
    
    // Get cameras
    $camerasQuery = [
        "from" => [["collectionId" => "surveillance_cameras"]],
        "select" => [
            "fields" => [
                ["fieldPath" => "name"],
                ["fieldPath" => "isActive"],
                ["fieldPath" => "lastActive"]
            ]
        ]
    ];
    
    $camerasResults = firestore_runQuery('surveillance_cameras', $camerasQuery);
    
    // Process cameras results
    foreach ($camerasResults as $row) {
        if (!empty($row['document'])) {
            $doc = $row['document'];
            $fields = $doc['fields'] ?? [];
            
            // Convert Firestore fields to simple values
            $cameraData = [];
            foreach ($fields as $k => $v) {
                if (isset($v['stringValue'])) $cameraData[$k] = $v['stringValue'];
                else if (isset($v['booleanValue'])) $cameraData[$k] = (bool)$v['booleanValue'];
                else if (isset($v['integerValue'])) $cameraData[$k] = (int)$v['integerValue'];
                else if (isset($v['doubleValue'])) $cameraData[$k] = (float)$v['doubleValue'];
                else if (isset($v['timestampValue'])) {
                    // Convert timestamp to PHP DateTime
                    $cameraData[$k] = new DateTime($v['timestampValue']);
                }
                else $cameraData[$k] = $v;
            }
            
            $cameraData['_id'] = basename($doc['name']);
            $cameras[] = $cameraData;
            
            $totalCameras++;
            
            // Check if camera is online (active within last 2 minutes)
            if ($cameraData['isActive'] ?? false) {
                $lastActive = $cameraData['lastActive'] ?? null;
                if ($lastActive instanceof DateTime) {
                    $diff = time() - $lastActive->getTimestamp();
                    if ($diff < 120) $onlineCameras++;
                }
            }
        }
    }
    
} catch (Exception $e) {
    error_log("Dashboard stats error: " . $e->getMessage());
    // Stats already initialized with defaults
}
?>

<div class="page-header">
    <div class="page-header-top">
        <div>
            <h1 class="page-title">Dashboard</h1>
            <p class="page-subtitle">Welcome back, <?php echo htmlspecialchars($_SESSION['user_name'] ?? 'Admin'); ?>! 👋</p>
        </div>
        <div class="header-actions">
            <button class="btn btn-ghost btn-icon">
                <span>🔔</span>
            </button>
            <div class="user-menu">
                <div class="user-avatar">
                    <?php echo strtoupper(substr($_SESSION['user_name'] ?? 'A', 0, 1)); ?>
                </div>
                <div>
                    <div style="font-weight: 600; font-size: 0.875rem;"><?php echo htmlspecialchars($_SESSION['user_name'] ?? 'Admin'); ?></div>
                    <div style="font-size: 0.75rem; color: var(--text-muted);"><?php echo ucfirst($_SESSION['user_role'] ?? 'staff'); ?></div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Stats Grid -->
<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-icon primary">
            <span>🏢</span>
        </div>
        <div class="stat-value" data-stat="totalServices"><?php echo $totalServices; ?></div>
        <div class="stat-label">Total Services</div>
        <div class="stat-change positive">
            <span>↑</span>
            <span><?php echo $openServices; ?> Open</span>
        </div>
    </div>
    
    <div class="stat-card">
        <div class="stat-icon warning">
            <span>⏳</span>
        </div>
        <div class="stat-value" data-stat="totalPending"><?php echo $totalPending; ?></div>
        <div class="stat-label">Pending in Queue</div>
        <div class="stat-change <?php echo $totalPending > 10 ? 'negative' : 'positive'; ?>">
            <span><?php echo $totalPending > 10 ? '↑' : '↓'; ?></span>
            <span><?php echo $totalActive; ?> Active</span>
        </div>
    </div>
    
    <div class="stat-card">
        <div class="stat-icon success">
            <span>✅</span>
        </div>
        <div class="stat-value" data-stat="totalServed"><?php echo $totalServed; ?></div>
        <div class="stat-label">Total Served Today</div>
        <div class="stat-change positive">
            <span>↑</span>
            <span>+<?php echo rand(10, 50); ?>% vs yesterday</span>
        </div>
    </div>
    
    <div class="stat-card">
        <div class="stat-icon danger">
            <span>📹</span>
        </div>
        <div class="stat-value" data-stat="onlineCameras"><?php echo $onlineCameras; ?></div>
        <div class="stat-label">Cameras Online</div>
        <div class="stat-change <?php echo $onlineCameras < $totalCameras ? 'negative' : 'positive'; ?>">
            <span><?php echo $onlineCameras < $totalCameras ? '⚠' : '✓'; ?></span>
            <span><?php echo $totalCameras; ?> Total</span>
        </div>
    </div>
</div>

<!-- Main Content Grid -->
<div style="display: grid; grid-template-columns: 2fr 1fr; gap: var(--spacing-xl); margin-bottom: var(--spacing-xl);">
    <!-- Live Queue Heatmap -->
    <div class="card">
        <div class="card-header">
            <h2 class="card-title">🔥 Live Queue Heatmap</h2>
            <button class="btn btn-ghost btn-sm">
                <span>↻</span>
                <span>Refresh</span>
            </button>
        </div>
        <div class="card-body" id="queue-heatmap">
            <?php
            if (!empty($services)) {
                foreach ($services as $service) {
                    $pending = $service['pendingCount'] ?? 0;
                    $intensity = min($pending / 10, 1) * 100;
                    $color = $intensity > 70 ? 'danger' : ($intensity > 40 ? 'warning' : 'success');
                    ?>
                    <div style="padding: var(--spacing-md); margin-bottom: var(--spacing-sm); background: var(--glass-bg); border-radius: var(--radius-md); display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <strong><?php echo htmlspecialchars($service['name'] ?? 'Unknown'); ?></strong>
                            <div style="font-size: 0.875rem; color: var(--text-muted);">
                                <?php echo $pending; ?> pending • <?php echo $service['activeCount'] ?? 0; ?> active
                            </div>
                        </div>
                        <div style="display: flex; align-items: center; gap: var(--spacing-md);">
                            <div style="width: 100px; height: 8px; background: rgba(255,255,255,0.1); border-radius: 999px; overflow: hidden;">
                                <div style="width: <?php echo $intensity; ?>%; height: 100%; background: var(--<?php echo $color; ?>-color); transition: width 0.3s;"></div>
                            </div>
                            <span class="badge badge-<?php echo $color; ?>"><?php echo round($intensity); ?>%</span>
                        </div>
                    </div>
                    <?php
                }
            } else {
                echo '<div class="text-center text-muted">No services found</div>';
            }
            ?>
        </div>
    </div>
    
    <!-- Camera Health -->
    <div class="card">
        <div class="card-header">
            <h2 class="card-title">📹 Camera Health</h2>
        </div>
        <div class="card-body">
            <?php
            if (!empty($cameras)) {
                foreach ($cameras as $camera) {
                    $isOnline = false;
                    if ($camera['isActive'] ?? false) {
                        $lastActive = $camera['lastActive'] ?? null;
                        if ($lastActive instanceof DateTime) {
                            $diff = time() - $lastActive->getTimestamp();
                            $isOnline = $diff < 120;
                        }
                    }
                    ?>
                    <div style="padding: var(--spacing-md); margin-bottom: var(--spacing-sm); background: rgba(255,255,255,0.03); border-radius: var(--radius-md); display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <span class="status-dot <?php echo $isOnline ? 'online' : 'offline'; ?>"></span>
                            <strong><?php echo htmlspecialchars($camera['name'] ?? 'Unknown'); ?></strong>
                        </div>
                        <span class="badge badge-<?php echo $isOnline ? 'success' : 'danger'; ?>">
                            <?php echo $isOnline ? 'Online' : 'Offline'; ?>
                        </span>
                    </div>
                    <?php
                }
            } else {
                echo '<div class="text-center text-muted">No cameras found</div>';
            }
            ?>
        </div>
    </div>
</div>

<!-- Recent Activity -->
<div class="card">
    <div class="card-header">
        <h2 class="card-title">📊 Recent Activity</h2>
        <a href="pages/logs.php" class="btn btn-ghost btn-sm">View All →</a>
    </div>
    <div class="card-body">
        <div class="table-container">
            <table class="table">
                <thead>
                    <tr>
                        <th>Time</th>
                        <th>User</th>
                        <th>Action</th>
                        <th>Target</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <?php
                    // Get recent logs using REST API
                    try {
                        $logsQuery = [
                            "from" => [["collectionId" => "audit_logs"]],
                            "orderBy" => [
                                ["field" => ["fieldPath" => "createdAt"], "direction" => "DESCENDING"]
                            ],
                            "limit" => 10
                        ];
                        
                        $logsResults = firestore_runQuery('audit_logs', $logsQuery);
                        
                        if (empty($logsResults)) {
                            echo '<tr><td colspan="5" class="text-center text-muted">No recent activity</td></tr>';
                        } else {
                            foreach ($logsResults as $row) {
                                if (!empty($row['document'])) {
                                    $doc = $row['document'];
                                    $fields = $doc['fields'] ?? [];
                                    
                                    // Convert Firestore fields to simple values
                                    $logData = [];
                                    foreach ($fields as $k => $v) {
                                        if (isset($v['stringValue'])) $logData[$k] = $v['stringValue'];
                                        else if (isset($v['booleanValue'])) $logData[$k] = (bool)$v['booleanValue'];
                                        else if (isset($v['integerValue'])) $logData[$k] = (int)$v['integerValue'];
                                        else if (isset($v['doubleValue'])) $logData[$k] = (float)$v['doubleValue'];
                                        else if (isset($v['timestampValue'])) {
                                            $timestamp = new DateTime($v['timestampValue']);
                                            $logData[$k] = $timestamp;
                                        }
                                        else $logData[$k] = $v;
                                    }
                                    
                                    $timeAgo = $logData['createdAt'] instanceof DateTime ? 
                                        $logData['createdAt']->format('H:i:s') : 'Unknown';
                                    ?>
                                    <tr>
                                        <td><?php echo $timeAgo; ?></td>
                                        <td><?php echo htmlspecialchars($logData['actorName'] ?? 'Unknown'); ?></td>
                                        <td><?php echo htmlspecialchars($logData['action'] ?? 'Unknown'); ?></td>
                                        <td style="font-family: monospace; font-size: 0.75rem;"><?php echo htmlspecialchars($logData['targetPath'] ?? 'N/A'); ?></td>
                                        <td><span class="badge badge-success">✓</span></td>
                                    </tr>
                                    <?php
                                }
                            }
                        }
                    } catch (Exception $e) {
                        echo '<tr><td colspan="5" class="text-center text-muted">Error loading activity: ' . htmlspecialchars($e->getMessage()) . '</td></tr>';
                    }
                    ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<?php include 'includes/footer.php'; ?>