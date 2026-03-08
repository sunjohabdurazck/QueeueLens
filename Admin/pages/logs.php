<?php
require_once '../config/config.php';
requireRole(ROLE_STAFF);

$pageTitle = 'Activity Logs';
include '../includes/header.php';

// Get logs with pagination
$page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
$perPage = 50;
$search = $_GET['search'] ?? '';

try {
    require_once '../config/firebase.php';
    $firebase = FirebaseAdmin::getInstance();
    $db = $firebase->getFirestore();
    
    $logsRef = $db->collection('audit_logs')->orderBy('createdAt', 'DESC')->limit($perPage * $page);
    $logs = $logsRef->documents();
    
    $logsArray = [];
    foreach ($logs as $log) {
        $data = $log->data();
        
        // Simple search filter
        if (!empty($search)) {
            $searchLower = strtolower($search);
            $actorName = strtolower($data['actorName'] ?? '');
            $action = strtolower($data['action'] ?? '');
            $target = strtolower($data['targetPath'] ?? '');
            
            if (strpos($actorName, $searchLower) === false && 
                strpos($action, $searchLower) === false && 
                strpos($target, $searchLower) === false) {
                continue;
            }
        }
        
        $logsArray[] = [
            'id' => $log->id(),
            'actorName' => $data['actorName'] ?? 'Unknown',
            'actorRole' => $data['actorRole'] ?? 'unknown',
            'action' => $data['action'] ?? 'UNKNOWN',
            'targetPath' => $data['targetPath'] ?? 'N/A',
            'ipAddress' => $data['ipAddress'] ?? 'unknown',
            'createdAt' => $data['createdAt'] ?? null,
            'metadata' => $data['metadata'] ?? []
        ];
    }
    
} catch (Exception $e) {
    error_log("Logs page error: " . $e->getMessage());
    $logsArray = [];
}
?>

<div class="page-header">
    <div class="page-header-top">
        <div>
            <h1 class="page-title">📝 Activity Logs</h1>
            <p class="page-subtitle">Complete audit trail of all system actions</p>
        </div>
        <div class="header-actions">
            <form method="GET" style="display: flex; gap: var(--spacing-md);">
                <input 
                    type="text" 
                    name="search" 
                    class="form-input" 
                    placeholder="Search logs..."
                    value="<?php echo htmlspecialchars($search); ?>"
                    style="width: 300px;"
                >
                <button type="submit" class="btn btn-primary">
                    <span>🔍</span>
                    <span>Search</span>
                </button>
                <?php if (!empty($search)): ?>
                <a href="logs.php" class="btn btn-secondary">
                    <span>✕</span>
                    <span>Clear</span>
                </a>
                <?php endif; ?>
            </form>
        </div>
    </div>
</div>

<!-- Filter Chips -->
<div style="display: flex; gap: var(--spacing-sm); margin-bottom: var(--spacing-xl); flex-wrap: wrap;">
    <button class="badge badge-primary" onclick="filterByAction('all')" style="cursor: pointer; padding: 0.5rem 1rem;">
        All Actions
    </button>
    <button class="badge badge-success" onclick="filterByAction('CREATE')" style="cursor: pointer; padding: 0.5rem 1rem;">
        Create
    </button>
    <button class="badge badge-warning" onclick="filterByAction('UPDATE')" style="cursor: pointer; padding: 0.5rem 1rem;">
        Update
    </button>
    <button class="badge badge-danger" onclick="filterByAction('DELETE')" style="cursor: pointer; padding: 0.5rem 1rem;">
        Delete
    </button>
    <button class="badge badge-info" onclick="filterByAction('LOGIN')" style="cursor: pointer; padding: 0.5rem 1rem;">
        Login/Logout
    </button>
</div>

<!-- Logs Table -->
<div class="card">
    <div class="card-body">
        <?php if (empty($logsArray)): ?>
        <div style="text-align: center; padding: 4rem; color: var(--text-muted);">
            <div style="font-size: 4rem; margin-bottom: 1rem;">📝</div>
            <h3>No logs found</h3>
            <p>No activity logs match your search criteria</p>
        </div>
        <?php else: ?>
        <div class="table-container">
            <table class="table" id="logsTable">
                <thead>
                    <tr>
                        <th style="width: 140px;">Timestamp</th>
                        <th>User</th>
                        <th>Role</th>
                        <th>Action</th>
                        <th>Target</th>
                        <th style="width: 120px;">IP Address</th>
                        <th style="width: 80px;">Details</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($logsArray as $log): ?>
                    <tr data-action="<?php echo htmlspecialchars($log['action']); ?>">
                        <td>
                            <?php
                            if ($log['createdAt']) {
                                $timestamp = $log['createdAt']->get()->getTimestamp();
                                echo '<div style="font-size: 0.875rem;">' . date('M d, Y', $timestamp) . '</div>';
                                echo '<div style="font-size: 0.75rem; color: var(--text-muted);">' . date('H:i:s', $timestamp) . '</div>';
                            } else {
                                echo '<span class="text-muted">Unknown</span>';
                            }
                            ?>
                        </td>
                        <td>
                            <strong><?php echo htmlspecialchars($log['actorName']); ?></strong>
                        </td>
                        <td>
                            <span class="badge badge-<?php 
                                echo $log['actorRole'] === 'admin' ? 'danger' : 
                                    ($log['actorRole'] === 'staff' ? 'warning' : 'info'); 
                            ?>">
                                <?php echo ucfirst($log['actorRole']); ?>
                            </span>
                        </td>
                        <td>
                            <span class="badge badge-<?php
                                $action = $log['action'];
                                if (strpos($action, 'CREATE') !== false) echo 'success';
                                elseif (strpos($action, 'UPDATE') !== false || strpos($action, 'TOGGLE') !== false) echo 'warning';
                                elseif (strpos($action, 'DELETE') !== false || strpos($action, 'KICK') !== false) echo 'danger';
                                else echo 'info';
                            ?>">
                                <?php echo htmlspecialchars($log['action']); ?>
                            </span>
                        </td>
                        <td style="font-family: monospace; font-size: 0.75rem; color: var(--text-muted);">
                            <?php echo htmlspecialchars($log['targetPath']); ?>
                        </td>
                        <td style="font-size: 0.75rem; color: var(--text-muted);">
                            <?php echo htmlspecialchars($log['ipAddress']); ?>
                        </td>
                        <td>
                            <?php if (!empty($log['metadata'])): ?>
                            <button 
                                class="btn btn-ghost btn-sm" 
                                onclick="showMetadata(<?php echo htmlspecialchars(json_encode($log['metadata'])); ?>)"
                            >
                                <span>ℹ️</span>
                            </button>
                            <?php endif; ?>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        
        <!-- Pagination -->
        <div style="display: flex; justify-content: center; gap: var(--spacing-sm); margin-top: var(--spacing-xl);">
            <?php if ($page > 1): ?>
            <a href="?page=<?php echo $page - 1; ?><?php echo !empty($search) ? '&search=' . urlencode($search) : ''; ?>" class="btn btn-secondary">
                <span>←</span>
                <span>Previous</span>
            </a>
            <?php endif; ?>
            
            <span class="btn btn-ghost" style="cursor: default;">
                Page <?php echo $page; ?>
            </span>
            
            <?php if (count($logsArray) >= $perPage): ?>
            <a href="?page=<?php echo $page + 1; ?><?php echo !empty($search) ? '&search=' . urlencode($search) : ''; ?>" class="btn btn-secondary">
                <span>Next</span>
                <span>→</span>
            </a>
            <?php endif; ?>
        </div>
        <?php endif; ?>
    </div>
</div>

<!-- Metadata Modal -->
<div id="metadataModal" class="modal-overlay">
    <div class="modal">
        <div class="modal-header">
            <h2 class="modal-title">Action Details</h2>
            <button class="modal-close">×</button>
        </div>
        <div class="modal-body">
            <pre id="metadataContent" style="background: var(--bg-primary); padding: var(--spacing-lg); border-radius: var(--radius-md); overflow-x: auto; color: var(--text-primary);"></pre>
        </div>
        <div class="modal-footer">
            <button class="btn btn-secondary" data-modal-close>Close</button>
        </div>
    </div>
</div>

<script>
function showMetadata(metadata) {
    const modal = document.getElementById('metadataModal');
    const content = document.getElementById('metadataContent');
    
    content.textContent = JSON.stringify(metadata, null, 2);
    modal.classList.add('active');
}

function filterByAction(actionType) {
    const rows = document.querySelectorAll('#logsTable tbody tr');
    
    rows.forEach(row => {
        const action = row.dataset.action;
        
        if (actionType === 'all') {
            row.style.display = '';
        } else {
            if (action.includes(actionType)) {
                row.style.display = '';
            } else {
                row.style.display = 'none';
            }
        }
    });
}

// Export logs
function exportLogs() {
    const rows = document.querySelectorAll('#logsTable tbody tr:not([style*="display: none"])');
    let csv = 'Timestamp,User,Role,Action,Target,IP Address\n';
    
    rows.forEach(row => {
        const cells = row.querySelectorAll('td');
        const timestamp = cells[0].textContent.trim().replace(/\n/g, ' ');
        const user = cells[1].textContent.trim();
        const role = cells[2].textContent.trim();
        const action = cells[3].textContent.trim();
        const target = cells[4].textContent.trim();
        const ip = cells[5].textContent.trim();
        
        csv += `"${timestamp}","${user}","${role}","${action}","${target}","${ip}"\n`;
    });
    
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'activity_logs_' + new Date().toISOString().split('T')[0] + '.csv';
    a.click();
    
    app.showNotification('Logs exported successfully', 'success');
}
</script>

<?php include '../includes/footer.php'; ?>
