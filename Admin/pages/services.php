<?php
require_once '../config/config.php';
requireRole(ROLE_STAFF);

$pageTitle = 'Services Management';
include '../includes/header.php';

// Get all services
$services = null;

try {
    require_once '../config/firebase.php';
    $firebase = FirebaseAdmin::getInstance();
    $db = $firebase->getFirestore();

    $servicesRef = $db->collection('services');
    $services = $servicesRef->documents();
} catch (Exception $e) {
    error_log("Services page error: " . $e->getMessage());
}
?>

<div class="page-header">
    <div class="page-header-top">
        <div>
            <h1 class="page-title">🏢 Services Management</h1>
            <p class="page-subtitle">Manage all queue services</p>
        </div>
        <div class="header-actions">
            <?php if (hasRole(ROLE_ADMIN)): ?>
                <button class="btn btn-primary" data-modal="addServiceModal">
                    <span>➕</span>
                    <span>Add Service</span>
                </button>
            <?php endif; ?>
        </div>
    </div>
</div>

<!-- Services Grid -->
<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: var(--spacing-lg);">
<?php
if ($services) {
    $hasAny = false;

    foreach ($services as $service) {
        $hasAny = true;

        $data = $service->data();
        $serviceId = $service->id();

        $name = (string)($data['name'] ?? 'Unknown');
        $description = (string)($data['description'] ?? '');

        $isOpen = (bool)($data['isOpen'] ?? false);
        $pending = (int)($data['pendingCount'] ?? 0);
        $active  = (int)($data['activeCount'] ?? 0);
        $served  = (int)($data['totalServed'] ?? 0);

        // REST version usually stores ISO strings
        $createdAt = $data['createdAt'] ?? null;
        $createdAtText = '';
        if (is_string($createdAt)) {
            $t = strtotime($createdAt);
            if ($t) $createdAtText = date('M d, Y', $t);
        } elseif (is_object($createdAt) && method_exists($createdAt, 'get') && method_exists($createdAt->get(), 'getTimestamp')) {
            // if ever using Timestamp wrapper
            $createdAtText = date('M d, Y', (int)$createdAt->get()->getTimestamp());
        }
?>
    <div
        class="card"
        data-service-id="<?= htmlspecialchars($serviceId) ?>"
        data-name="<?= htmlspecialchars($name) ?>"
        data-description="<?= htmlspecialchars($description) ?>"
        data-isopen="<?= $isOpen ? '1' : '0' ?>"
        data-pending="<?= $pending ?>"
        data-active="<?= $active ?>"
        data-served="<?= $served ?>"
    >
        <div class="card-header">
            <div>
                <h3 class="card-title"><?= htmlspecialchars($name) ?></h3>
                <span class="badge badge-<?= $isOpen ? 'success' : 'danger' ?>">
                    <?= $isOpen ? '🟢 Open' : '🔴 Closed' ?>
                </span>
            </div>

            <button
                class="btn btn-ghost btn-icon"
                onclick="toggleService('<?= htmlspecialchars($serviceId) ?>', <?= $isOpen ? 'false' : 'true' ?>)"
                title="<?= $isOpen ? 'Close service' : 'Open service' ?>"
            >
                <span><?= $isOpen ? '⏸️' : '▶️' ?></span>
            </button>
        </div>

        <div class="card-body">
            <?php if ($description !== ''): ?>
                <p style="color: var(--text-secondary); margin-bottom: var(--spacing-lg);">
                    <?= htmlspecialchars($description) ?>
                </p>
            <?php endif; ?>

            <!-- Stats -->
            <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: var(--spacing-md); margin-bottom: var(--spacing-lg);">
                <div style="text-align: center; padding: var(--spacing-md); background: rgba(245, 158, 11, 0.1); border-radius: var(--radius-md);">
                    <div style="font-size: 1.5rem; font-weight: 700; color: var(--warning-color);"><?= $pending ?></div>
                    <div style="font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase;">Pending</div>
                </div>
                <div style="text-align: center; padding: var(--spacing-md); background: rgba(59, 130, 246, 0.1); border-radius: var(--radius-md);">
                    <div style="font-size: 1.5rem; font-weight: 700; color: var(--info-color);"><?= $active ?></div>
                    <div style="font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase;">Active</div>
                </div>
                <div style="text-align: center; padding: var(--spacing-md); background: rgba(16, 185, 129, 0.1); border-radius: var(--radius-md);">
                    <div style="font-size: 1.5rem; font-weight: 700; color: var(--success-color);"><?= $served ?></div>
                    <div style="font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase;">Served</div>
                </div>
            </div>

            <!-- Actions -->
            <div style="display: flex; gap: var(--spacing-sm); flex-wrap: wrap;">
                <button class="btn btn-primary btn-sm" onclick="window.location.href='queue.php#service-<?= htmlspecialchars($serviceId) ?>'">
                    <span>📋</span>
                    <span>View Queue</span>
                </button>

                <?php if (hasRole(ROLE_ADMIN)): ?>
                    <button class="btn btn-secondary btn-sm" type="button" onclick="editService('<?= htmlspecialchars($serviceId) ?>')">
                        <span>✏️</span>
                        <span>Edit</span>
                    </button>

                    <button class="btn btn-ghost btn-sm" type="button" onclick="resetCounts('<?= htmlspecialchars($serviceId) ?>', '<?= htmlspecialchars($name) ?>')">
                        <span>↻</span>
                        <span>Reset</span>
                    </button>

                    <button class="btn btn-danger btn-sm" type="button" onclick="deleteService('<?= htmlspecialchars($serviceId) ?>', '<?= htmlspecialchars($name) ?>')">
                        <span>🗑️</span>
                    </button>
                <?php endif; ?>
            </div>

            <!-- Created info -->
            <?php if ($createdAtText !== ''): ?>
                <div style="margin-top: var(--spacing-lg); padding-top: var(--spacing-lg); border-top: 1px solid var(--glass-border); font-size: 0.75rem; color: var(--text-muted);">
                    Created: <?= htmlspecialchars($createdAtText) ?>
                </div>
            <?php endif; ?>
        </div>
    </div>
<?php
    }

    if (!$hasAny) {
        echo '<div class="card" style="grid-column: 1 / -1; text-align: center; padding: 4rem;">
                <div style="font-size: 4rem; margin-bottom: 1rem;">🏢</div>
                <h3>No services yet</h3>
                <p style="color: var(--text-muted); margin: 1rem 0;">Add your first service to get started</p>';
        if (hasRole(ROLE_ADMIN)) {
            echo '<button class="btn btn-primary" data-modal="addServiceModal">Add Service</button>';
        }
        echo '</div>';
    }
} else {
    echo '<div class="card" style="grid-column: 1 / -1; text-align: center; padding: 4rem;">
            <div style="font-size: 4rem; margin-bottom: 1rem;">🏢</div>
            <h3>Could not load services</h3>
            <p style="color: var(--text-muted); margin: 1rem 0;">Check server logs.</p>
          </div>';
}
?>
</div>

<?php if (hasRole(ROLE_ADMIN)): ?>
<!-- Add Service Modal -->
<div id="addServiceModal" class="modal-overlay">
    <div class="modal">
        <div class="modal-header">
            <h2 class="modal-title">➕ Add New Service</h2>
            <button class="modal-close" data-modal-close>×</button>
        </div>

        <form data-ajax action="/queuelens/api/services.php" method="POST">
            <input type="hidden" name="api_action" value="create">
            <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">

            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label">Service Name *</label>
                    <input type="text" name="name" class="form-input" required placeholder="e.g. ICT Printing Services">
                </div>

                <div class="form-group">
  <label class="form-label">Service ID *</label>
  <input
    type="text"
    name="id"
    class="form-input"
    required
    placeholder="e.g. svc_ict_printing"
    pattern="[a-z0-9_]{3,50}"
    title="Use 3–50 chars: lowercase letters, numbers, underscore only"
  >
  <small style="color: var(--text-muted); display:block; margin-top:6px;">
    Allowed: a-z, 0-9, underscore (_). No spaces.
  </small>
</div>


                <div class="form-group">
                    <label class="form-label">Description</label>
                    <textarea name="description" class="form-textarea" rows="3" placeholder="Brief description of this service"></textarea>
                </div>

                <div class="form-group">
                    <label class="checkbox-label">
                        <input type="checkbox" name="isOpen" checked>
                        <span>Service is open</span>
                    </label>
                </div>
            </div>

            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-modal-close>Cancel</button>
                <button type="submit" class="btn btn-primary">
                    <span>➕</span>
                    <span>Add Service</span>
                </button>
            </div>
        </form>
    </div>
</div>

<!-- Edit Service Modal -->
<div class="modal-overlay" id="modalEditService">
  <div class="modal">
    <div class="modal-header">
      <h2>Edit Service</h2>
      <button type="button" class="modal-close" data-modal-close>&times;</button>
    </div>

    <form data-ajax action="/queuelens/api/services.php" method="POST">
      <input type="hidden" name="api_action" value="update">
      <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
      <input type="hidden" name="id" id="edit_service_id">

      <div class="modal-body">

        <!-- Editable -->
        <div class="form-group">
          <label class="form-label">Service Name *</label>
          <input type="text"
                 name="name"
                 id="edit_service_name"
                 class="form-input"
                 required>
        </div>

        <div class="form-group">
          <label class="form-label">Description</label>
          <textarea name="description"
                    id="edit_service_description"
                    class="form-textarea"
                    rows="3"></textarea>
        </div>

        <div class="form-group">
          <label class="checkbox-label">
            <input type="checkbox"
                   name="isOpen"
                   id="edit_service_isOpen">
            <span>Service is open</span>
          </label>
        </div>

        <!-- Read-only Stats -->
        <div style="margin-top:20px;">
          <label class="form-label">Current Stats</label>

          <div style="display:grid; grid-template-columns: repeat(3, 1fr); gap:12px; margin-top:8px;">
            
            <div class="form-group">
              <label class="form-label">Pending</label>
              <input type="number"
                     id="edit_service_pending"
                     class="form-input"
                     readonly>
            </div>

            <div class="form-group">
              <label class="form-label">Active</label>
              <input type="number"
                     id="edit_service_active"
                     class="form-input"
                     readonly>
            </div>

            <div class="form-group">
              <label class="form-label">Total Served</label>
              <input type="number"
                     id="edit_service_served"
                     class="form-input"
                     readonly>
            </div>

          </div>
        </div>

      </div>

      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-modal-close>Cancel</button>
        <button type="submit" class="btn btn-primary">Save Changes</button>
      </div>
    </form>
  </div>
</div>

<?php endif; ?>

<script>
async function toggleService(serviceId, newStatus) {
    try {
        const formData = new FormData();
        formData.append('api_action', 'toggle');
        formData.append('id', serviceId);
        formData.append('isOpen', newStatus ? 'on' : '');
        formData.append('csrf_token', '<?php echo generateCSRFToken(); ?>');

        const response = await fetch('/queuelens/api/services.php', {
            method: 'POST',
            body: formData
        });

        const raw = await response.text();
        let data = null;
        try { data = JSON.parse(raw); } catch (e) {}

        if (!response.ok || !data) {
            console.error('toggleService non-JSON:', raw);
            app.showNotification('Server error (toggle). Check console.', 'danger');
            return;
        }

        if (data.success) {
            app.showNotification(data.message || 'Updated', 'success');
            setTimeout(() => location.reload(), 500);
        } else {
            app.showNotification(data.message || 'Failed to toggle service', 'danger');
        }
    } catch (error) {
        console.error('Toggle service error:', error);
        app.showNotification('An error occurred', 'danger');
    }
}

async function resetCounts(serviceId, serviceName) {
    if (!confirm(`Reset all counters for "${serviceName}"? This will set pending, active, and total served to 0.`)) return;

    try {
        const formData = new FormData();
        formData.append('api_action', 'reset_counts');
        formData.append('id', serviceId);
        formData.append('csrf_token', '<?php echo generateCSRFToken(); ?>');

        const response = await fetch('/queuelens/api/services.php', {
            method: 'POST',
            body: formData
        });

        const raw = await response.text();
        let data = null;
        try { data = JSON.parse(raw); } catch (e) {}

        if (!response.ok || !data) {
            console.error('resetCounts non-JSON:', raw);
            app.showNotification('Server error (reset). Check console.', 'danger');
            return;
        }

        if (data.success) {
            app.showNotification(data.message || 'Reset done', 'success');
            setTimeout(() => location.reload(), 500);
        } else {
            app.showNotification(data.message || 'Failed to reset counts', 'danger');
        }
    } catch (error) {
        console.error('Reset counts error:', error);
        app.showNotification('An error occurred', 'danger');
    }
}

async function deleteService(serviceId, serviceName) {
    if (!confirm(`Delete "${serviceName}"? This action cannot be undone!`)) return;

    try {
        const formData = new FormData();
        formData.append('api_action', 'delete');
        formData.append('id', serviceId);
        formData.append('csrf_token', '<?php echo generateCSRFToken(); ?>');

        const response = await fetch('/queuelens/api/services.php', {
            method: 'POST',
            body: formData
        });

        const raw = await response.text();
        let data = null;
        try { data = JSON.parse(raw); } catch (e) {}

        if (!response.ok || !data) {
            console.error('deleteService non-JSON:', raw);
            app.showNotification('Server error (delete). Check console.', 'danger');
            return;
        }

        if (data.success) {
            app.showNotification(data.message || 'Deleted', 'success');
            setTimeout(() => location.reload(), 700);
        } else {
            app.showNotification(data.message || 'Failed to delete service', 'danger');
        }
    } catch (error) {
        console.error('Delete service error:', error);
        app.showNotification('An error occurred', 'danger');
    }
}

function editService(serviceId) {
    const card = document.querySelector(`.card[data-service-id="${serviceId}"]`);
    if (!card) {
        app.showNotification('Service not found in UI', 'danger');
        return;
    }

    document.getElementById('edit_service_id').value = serviceId;
    document.getElementById('edit_service_name').value = card.dataset.name || '';
    document.getElementById('edit_service_description').value = card.dataset.description || '';
    document.getElementById('edit_service_isOpen').checked = (card.dataset.isopen === '1');

    document.getElementById('edit_service_pending').value = card.dataset.pending || 0;
    document.getElementById('edit_service_active').value = card.dataset.active || 0;
    document.getElementById('edit_service_served').value = card.dataset.served || 0;

    app.openModal('modalEditService');
}
</script>

<?php include '../includes/footer.php'; ?>
