<?php
require_once '../config/config.php';
requireRole(ROLE_STAFF);

$pageTitle = 'Camera Management';
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
} catch (Exception $e) {
    error_log("Camera page error: " . $e->getMessage());
}
?>

<div class="page-header">
    <div class="page-header-top">
        <div>
            <h1 class="page-title">📹 Surveillance Control Center</h1>
            <p class="page-subtitle">Manage and monitor all camera feeds across campus</p>
        </div>
        <div class="header-actions">
            <button class="btn btn-secondary" data-modal="addCameraModal">
                <span>➕</span>
                <span>Add Camera</span>
            </button>
            <button class="btn btn-primary" onclick="window.location.href='3d-map.php'">
                <span>🗺️</span>
                <span>3D Map View</span>
            </button>
        </div>
    </div>
</div>

<!-- Camera Grid -->
<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: var(--spacing-lg); margin-bottom: var(--spacing-xl);">
    <?php
    if (isset($cameras)) {
        foreach ($cameras as $camera) {
            $data = $camera->data();
            $cameraId = $camera->id();
            $isOnline = false;
            
            if ($data['isActive'] ?? false) {
                $lastActive = $data['lastActive'] ?? null;
                if ($lastActive) {
                    // FIX: Check the type of $lastActive and handle accordingly
                    if (is_object($lastActive) && method_exists($lastActive, 'getTimestamp')) {
                        // It's a Firestore Timestamp object
                        $diff = time() - $lastActive->getTimestamp();
                        $isOnline = $diff < 120;
                    } elseif ($lastActive instanceof DateTime) {
                        // It's already a DateTime object
                        $diff = time() - $lastActive->getTimestamp();
                        $isOnline = $diff < 120;
                    } elseif (is_string($lastActive)) {
                        // It's a string timestamp
                        $timestamp = strtotime($lastActive);
                        $diff = time() - $timestamp;
                        $isOnline = $diff < 120;
                    } elseif (is_array($lastActive) && isset($lastActive['seconds'])) {
                        // It's an array with seconds (Firestore format)
                        $diff = time() - $lastActive['seconds'];
                        $isOnline = $diff < 120;
                    }
                }
            }
            
            $cameraTypes = ['MJPEG', 'RTSP', 'HLS', 'WebRTC'];
            $typeIndex = $data['type'] ?? 0;
            $typeName = $cameraTypes[$typeIndex] ?? 'Unknown';
            ?>
            <div class="card" style="position: relative; overflow: hidden;">
                <!-- Status Indicator -->
                <div style="position: absolute; top: 1rem; right: 1rem; z-index: 10;">
                    <span class="badge badge-<?php echo $isOnline ? 'success' : 'danger'; ?>">
                        <span class="status-dot <?php echo $isOnline ? 'online' : 'offline'; ?>"></span>
                        <?php echo $isOnline ? 'Live' : 'Offline'; ?>
                    </span>
                </div>
                
                <!-- Stream Preview -->
                <div style="background: #000; aspect-ratio: 16/9; border-radius: var(--radius-md); overflow: hidden; margin-bottom: var(--spacing-md); position: relative;">
                    <?php if ($isOnline && ($data['isActive'] ?? false)): ?>
                        <img 
                            src="<?php echo htmlspecialchars($data['streamUrl'] ?? ''); ?>" 
                            alt="<?php echo htmlspecialchars($data['name']); ?>"
                            style="width: 100%; height: 100%; object-fit: cover;"
                            onerror="this.src='data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'100\' height=\'100\'%3E%3Crect fill=\'%23334155\' width=\'100\' height=\'100\'/%3E%3Ctext x=\'50%\' y=\'50%\' text-anchor=\'middle\' dominant-baseline=\'middle\' fill=\'%2394a3b8\' font-family=\'sans-serif\' font-size=\'14\'%3ENo Signal%3C/text%3E%3C/svg%3E'"
                        >
                    <?php else: ?>
                        <div style="display: flex; align-items: center; justify-content: center; height: 100%; color: var(--text-muted);">
                            <div style="text-align: center;">
                                <div style="font-size: 3rem; margin-bottom: 0.5rem;">📹</div>
                                <div>Camera Offline</div>
                            </div>
                        </div>
                    <?php endif; ?>
                    
                    <!-- Quick Actions Overlay -->
                    <div style="position: absolute; bottom: 0; left: 0; right: 0; background: linear-gradient(to top, rgba(0,0,0,0.8), transparent); padding: var(--spacing-md); display: flex; gap: var(--spacing-sm);">
                        <button class="btn btn-sm btn-ghost" onclick="openStreamWindow('<?php echo htmlspecialchars($data['streamUrl'] ?? ''); ?>')">
                            <span>🔗</span>
                        </button>
                        <button class="btn btn-sm btn-ghost" onclick="testCameraStream('<?php echo $cameraId; ?>')">
                            <span>🧪</span>
                        </button>
                        <button class="btn btn-sm btn-ghost" onclick="refreshCamera('<?php echo $cameraId; ?>')">
                            <span>↻</span>
                        </button>
                    </div>
                </div>
                
                <!-- Camera Info -->
                <div>
                    <h3 style="font-size: 1.125rem; font-weight: 600; margin-bottom: var(--spacing-sm);">
                        <?php echo htmlspecialchars($data['name'] ?? 'Unknown Camera'); ?>
                    </h3>
                    
                    <div style="display: flex; flex-wrap: wrap; gap: var(--spacing-sm); margin-bottom: var(--spacing-md);">
                        <span class="badge badge-primary"><?php echo $typeName; ?></span>
                        <span class="badge badge-info">
                            <?php
                            if (isset($services)) {
                                $serviceName = 'Unassigned';
                                foreach ($services as $service) {
                                    if ($service->id() === ($data['serviceId'] ?? '')) {
                                        $serviceName = $service->data()['name'] ?? 'Unknown';
                                        break;
                                    }
                                }
                                echo $serviceName;
                            }
                            ?>
                        </span>
                    </div>
                    
                    <?php if (!empty($data['description'])): ?>
                        <p style="color: var(--text-muted); font-size: 0.875rem; margin-bottom: var(--spacing-md);">
                            <?php echo htmlspecialchars($data['description']); ?>
                        </p>
                    <?php endif; ?>
                    
                    <!-- Position Info -->
                    <div style="display: flex; gap: var(--spacing-md); margin-bottom: var(--spacing-md); font-size: 0.75rem; color: var(--text-muted); font-family: monospace;">
                        <div>X: <?php echo number_format($data['position']['x'] ?? 0, 1); ?></div>
                        <div>Y: <?php echo number_format($data['position']['y'] ?? 0, 1); ?></div>
                        <div>Z: <?php echo number_format($data['position']['z'] ?? 0, 1); ?></div>
                    </div>
                    
                    <!-- Actions -->
                    <div style="display: flex; gap: var(--spacing-sm); padding-top: var(--spacing-md); border-top: 1px solid var(--glass-border);">
                        <button class="btn btn-secondary btn-sm" onclick="editCamera('<?php echo $cameraId; ?>', <?php echo htmlspecialchars(json_encode($data, JSON_HEX_APOS | JSON_HEX_QUOT)); ?>)">
                            <span>✏️</span>
                            <span>Edit</span>
                        </button>
                        <button class="btn btn-ghost btn-sm" onclick="duplicateCamera('<?php echo $cameraId; ?>')">
                            <span>📋</span>
                            <span>Duplicate</span>
                        </button>
                        <button class="btn btn-danger btn-sm" onclick="deleteCamera('<?php echo $cameraId; ?>', '<?php echo htmlspecialchars(addslashes($data['name'] ?? '')); ?>')" style="margin-left: auto;">
                            <span>🗑️</span>
                        </button>
                    </div>
                </div>
            </div>
            <?php
        }
    } else {
        echo '<div class="card" style="grid-column: 1 / -1; text-align: center; padding: 4rem;">
                <div style="font-size: 4rem; margin-bottom: 1rem;">📹</div>
                <h3>No cameras yet</h3>
                <p style="color: var(--text-muted); margin: 1rem 0;">Add your first camera to get started</p>
                <button class="btn btn-primary" data-modal="addCameraModal">Add Camera</button>
              </div>';
    }
    ?>
</div>

<!-- Add Camera Modal -->
<div id="addCameraModal" class="modal-overlay">
    <div class="modal">
        <div class="modal-header">
            <h2 class="modal-title">➕ Add New Camera</h2>
            <button class="modal-close">×</button>
        </div>
        <form data-ajax action="<?= BASE_PATH ?>/api/cameras_create.php" method="POST">
            <input type="hidden" name="action" value="create">
            <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
            
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label">Camera Name *</label>
                    <input type="text" name="name" class="form-input" required placeholder="e.g. ICT Printing Front">
                </div>
                
                <div class="form-group">
                    <label class="form-label">Service *</label>
                    <select name="serviceId" class="form-select" required>
                        <option value="">Select service...</option>
                        <?php
                        if (isset($services)) {
                            foreach ($services as $service) {
                                $sData = $service->data();
                                echo '<option value="' . htmlspecialchars($service->id()) . '">' . htmlspecialchars($sData['name'] ?? 'Unknown') . '</option>';
                            }
                        }
                        ?>
                    </select>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Stream URL *</label>
                    <input type="url" name="streamUrl" class="form-input" required placeholder="http://192.168.1.102:8080/video">
                    <span class="form-help">Full URL to camera stream</span>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Camera Type *</label>
                    <select name="type" class="form-select" required>
                        <option value="0">MJPEG (IP Webcam)</option>
                        <option value="1">RTSP (Raspberry Pi)</option>
                        <option value="2">HLS</option>
                        <option value="3">WebRTC</option>
                    </select>
                </div>
                
                <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: var(--spacing-md);">
                    <div class="form-group">
                        <label class="form-label">Position X</label>
                        <input type="number" step="0.1" name="positionX" class="form-input" value="0" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Position Y</label>
                        <input type="number" step="0.1" name="positionY" class="form-input" value="0" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Position Z</label>
                        <input type="number" step="0.1" name="positionZ" class="form-input" value="0" required>
                    </div>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Description</label>
                    <textarea name="description" class="form-textarea" rows="3" placeholder="Optional notes about this camera"></textarea>
                </div>
                
                <div class="form-group">
                    <label class="checkbox-label">
                        <input type="checkbox" name="isActive" checked>
                        <span>Camera is active</span>
                    </label>
                </div>
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-modal-close>Cancel</button>
                <button type="submit" class="btn btn-primary">
                    <span>➕</span>
                    <span>Add Camera</span>
                </button>
            </div>
        </form>
    </div>
</div>

<!-- Edit Camera Modal -->
<div id="editCameraModal" class="modal-overlay" style="display: none;">
    <div class="modal">
        <div class="modal-header">
            <h2 class="modal-title">✏️ Edit Camera</h2>
            <button class="modal-close" onclick="app.hideModal('editCameraModal')">×</button>
        </div>
        <form data-ajax action="<?= BASE_PATH ?>/api/cameras_update.php" method="POST">
            <input type="hidden" name="action" value="update">
            <input type="hidden" name="id" id="editCameraId" value="">
            <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
            
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label">Camera Name *</label>
                    <input type="text" name="name" id="editCameraName" class="form-input" required placeholder="e.g. ICT Printing Front">
                </div>
                
                <div class="form-group">
                    <label class="form-label">Service *</label>
                    <select name="serviceId" id="editCameraServiceId" class="form-select" required>
                        <option value="">Select service...</option>
                        <?php
                        if (isset($services)) {
                            foreach ($services as $service) {
                                $sData = $service->data();
                                echo '<option value="' . htmlspecialchars($service->id()) . '">' . htmlspecialchars($sData['name'] ?? 'Unknown') . '</option>';
                            }
                        }
                        ?>
                    </select>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Stream URL *</label>
                    <input type="url" name="streamUrl" id="editStreamUrl" class="form-input" required placeholder="http://192.168.1.102:8080/video">
                    <span class="form-help">Full URL to camera stream</span>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Camera Type *</label>
                    <select name="type" id="editCameraType" class="form-select" required>
                        <option value="0">MJPEG (IP Webcam)</option>
                        <option value="1">RTSP (Raspberry Pi)</option>
                        <option value="2">HLS</option>
                        <option value="3">WebRTC</option>
                    </select>
                </div>
                
                <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: var(--spacing-md);">
                    <div class="form-group">
                        <label class="form-label">Position X</label>
                        <input type="number" step="0.1" name="positionX" id="editPositionX" class="form-input" value="0" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Position Y</label>
                        <input type="number" step="0.1" name="positionY" id="editPositionY" class="form-input" value="0" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Position Z</label>
                        <input type="number" step="0.1" name="positionZ" id="editPositionZ" class="form-input" value="0" required>
                    </div>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Description</label>
                    <textarea name="description" id="editDescription" class="form-textarea" rows="3" placeholder="Optional notes about this camera"></textarea>
                </div>
                
                <div class="form-group">
                    <label class="checkbox-label">
                        <input type="checkbox" name="isActive" id="editIsActive">
                        <span>Camera is active</span>
                    </label>
                </div>
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="app.hideModal('editCameraModal')">Cancel</button>
                <button type="submit" class="btn btn-primary">
                    <span>💾</span>
                    <span>Update Camera</span>
                </button>
            </div>
        </form>
    </div>
</div>

<script>
(function () {
    // Ensure global app exists
    if (typeof window.app === 'undefined') {
        window.app = {
            showModal: function(modalId) {
                const el = document.getElementById(modalId);
                if (el) el.style.display = 'flex';
            },
            hideModal: function(modalId) {
                const el = document.getElementById(modalId);
                if (el) el.style.display = 'none';
            },
            showNotification: function(message, type) {
                alert(message);
            }
        };
    }

    // ✅ Open modal buttons: data-modal="addCameraModal"
    document.querySelectorAll('[data-modal]').forEach(btn => {
        btn.addEventListener('click', () => {
            const modalId = btn.getAttribute('data-modal');
            window.app.showModal(modalId);
        });
    });

    // ✅ Close buttons: .modal-close
    document.querySelectorAll('.modal-close').forEach(btn => {
        btn.addEventListener('click', () => {
            const overlay = btn.closest('.modal-overlay');
            if (overlay) overlay.style.display = 'none';
        });
    });

    // ✅ Close buttons: [data-modal-close]
    document.querySelectorAll('[data-modal-close]').forEach(btn => {
        btn.addEventListener('click', () => {
            const overlay = btn.closest('.modal-overlay');
            if (overlay) overlay.style.display = 'none';
        });
    });

    // ✅ Close if click outside modal content
    document.querySelectorAll('.modal-overlay').forEach(overlay => {
        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) {
                overlay.style.display = 'none';
            }
        });
    });
})();

// ---------------- Your existing functions ----------------
function openStreamWindow(url) {
    window.open(url, '_blank', 'width=800,height=600');
}

function testCameraStream(cameraId) {
    app.showNotification('Testing camera stream...', 'info');
}

function refreshCamera(cameraId) {
    location.reload();
}

function editCamera(cameraId, cameraData) {
    document.getElementById('editCameraId').value = cameraId;
    document.getElementById('editCameraName').value = cameraData.name || '';
    document.getElementById('editCameraServiceId').value = cameraData.serviceId || '';
    document.getElementById('editStreamUrl').value = cameraData.streamUrl || '';

    // force string for select
    document.getElementById('editCameraType').value = String(cameraData.type ?? 0);

    document.getElementById('editPositionX').value = cameraData.position?.x ?? 0;
    document.getElementById('editPositionY').value = cameraData.position?.y ?? 0;
    document.getElementById('editPositionZ').value = cameraData.position?.z ?? 0;

    document.getElementById('editDescription').value = cameraData.description || '';
    document.getElementById('editIsActive').checked = !!cameraData.isActive;

    // Show modal
    app.showModal('editCameraModal');
}

function duplicateCamera(cameraId) {
    app.showNotification('Duplicate feature coming soon', 'info');
}

function deleteCamera(cameraId, name) {
    if (!confirm(`Are you sure you want to delete camera "${name}"?`)) return;

    const form = document.createElement('form');
    form.method = 'POST';
    form.action = '<?= BASE_PATH ?>/api/cameras_delete.php';

    const idInput = document.createElement('input');
    idInput.type = 'hidden';
    idInput.name = 'id';
    idInput.value = cameraId;

    const csrfInput = document.createElement('input');
    csrfInput.type = 'hidden';
    csrfInput.name = 'csrf_token';
    csrfInput.value = '<?php echo generateCSRFToken(); ?>';

    form.appendChild(idInput);
    form.appendChild(csrfInput);
    document.body.appendChild(form);
    form.submit();
}
</script>


<?php include '../includes/footer.php'; ?>