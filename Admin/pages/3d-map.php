<?php
require_once '../config/config.php';
requireRole(ROLE_STAFF);

$pageTitle = '3D Campus Map';
include '../includes/header.php';

// Get cameras and services
try {
    require_once '../config/firebase.php';
    $firebase = FirebaseAdmin::getInstance();
    $db = $firebase->getFirestore();
    
    $camerasRef = $db->collection('surveillance_cameras');
    $cameras = $camerasRef->documents();
    
    $servicesRef = $db->collection('services');
    $services = $servicesRef->documents();
    
    $camerasArray = [];
    foreach ($cameras as $camera) {
        $data = $camera->data();
        $camerasArray[] = [
            'id' => $camera->id(),
            'name' => $data['name'] ?? '',
            'position' => $data['position'] ?? ['x' => 0, 'y' => 0, 'z' => 0],
            'isActive' => $data['isActive'] ?? false,
            'lastActive' => isset($data['lastActive']) ? $data['lastActive']->get()->getTimestamp() : null
        ];
    }
} catch (Exception $e) {
    $camerasArray = [];
}
?>

<div class="page-header">
    <div class="page-header-top">
        <div>
            <h1 class="page-title">🗺️ 3D Campus Map</h1>
            <p class="page-subtitle">Interactive camera positioning and campus overview</p>
        </div>
        <div class="header-actions">
            <button class="btn btn-secondary" onclick="campusMap.render()">
                <span>↻</span>
                <span>Refresh</span>
            </button>
            <button class="btn btn-primary" onclick="window.location.href='cameras.php'">
                <span>📹</span>
                <span>Camera List</span>
            </button>
        </div>
    </div>
</div>

<div class="card" style="margin-bottom: var(--spacing-xl);">
    <div class="card-body">
        <canvas id="campus-map-3d" style="width: 100%; height: 600px; background: var(--bg-primary); border-radius: var(--radius-lg);"></canvas>
    </div>
</div>

<!-- Camera Details Panel -->
<div id="cameraDetails" class="card" style="display: none;">
    <div class="card-header">
        <h2 class="card-title">Camera Details</h2>
        <button class="btn btn-ghost btn-sm" onclick="document.getElementById('cameraDetails').style.display='none'">×</button>
    </div>
    <div class="card-body" id="cameraDetailsContent">
        <!-- Populated by JavaScript -->
    </div>
</div>

<script>
// Initialize 3D map with camera data
document.addEventListener('DOMContentLoaded', function() {
    const cameras = <?php echo json_encode($camerasArray); ?>;
    
    if (campusMap) {
        campusMap.setCameras(cameras);
        
        // Override camera select handler
        campusMap.onCameraSelect = function(camera) {
            const detailsPanel = document.getElementById('cameraDetails');
            const detailsContent = document.getElementById('cameraDetailsContent');
            
            const isOnline = camera.isActive && camera.lastActive && 
                             (Date.now() / 1000 - camera.lastActive) < 120;
            
            detailsContent.innerHTML = `
                <div style="margin-bottom: 1rem;">
                    <h3 style="font-size: 1.25rem; margin-bottom: 0.5rem;">${camera.name}</h3>
                    <span class="badge badge-${isOnline ? 'success' : 'danger'}">
                        ${isOnline ? 'Online' : 'Offline'}
                    </span>
                </div>
                <div style="display: grid; gap: 1rem;">
                    <div>
                        <div style="color: var(--text-muted); font-size: 0.875rem;">Position</div>
                        <div style="font-family: monospace;">
                            X: ${camera.position.x.toFixed(1)}, 
                            Y: ${camera.position.y.toFixed(1)}, 
                            Z: ${camera.position.z.toFixed(1)}
                        </div>
                    </div>
                    <div style="display: flex; gap: 0.5rem;">
                        <button class="btn btn-primary btn-sm" onclick="window.location.href='cameras.php'">
                            View Details
                        </button>
                        <button class="btn btn-secondary btn-sm" onclick="document.getElementById('cameraDetails').style.display='none'">
                            Close
                        </button>
                    </div>
                </div>
            `;
            
            detailsPanel.style.display = 'block';
        };
    }
});
</script>

<?php include '../includes/footer.php'; ?>
