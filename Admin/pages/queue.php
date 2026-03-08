<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . '/../config/config.php';
requireRole(ROLE_STAFF);

require_once __DIR__ . '/../config/firebase.php';
require_once __DIR__ . '/../config/firestore_rest.php';

$firestore = FirebaseAdmin::getInstance()->getFirestore();

$pageTitle = 'Queue Management';
include __DIR__ . '/../includes/header.php';

$error = null;
$services = [];

try {
    $services = $firestore->collection('services')->documents();
} catch (Throwable $e) {
    $error = $e->getMessage();
    error_log("Queue services load error: " . $e->getMessage());
}

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

// Cache user names per request (avoid repeated reads)
$userNameCache = [];
function getUserNameByUid($firestore, $uid, &$cache): string {
    if (!$uid) return 'Unknown';

    if (isset($cache[$uid])) {
        return $cache[$uid];
    }

    try {
        // Firestore PHP SDK: snapshot() exists
        // If yours doesn't, comment this and use your REST get instead.
        $doc = $firestore->collection('users')->document($uid)->snapshot();

        if ($doc && method_exists($doc, 'exists') && $doc->exists()) {
            $data = $doc->data();

            // IMPORTANT: ensure we return STRING not array/object
            $name = $data['name'] ?? null;
            if (is_string($name) && trim($name) !== '') {
                $cache[$uid] = $name;
                return $name;
            }
        }
    } catch (Throwable $e) {
        error_log("User fetch error ($uid): " . $e->getMessage());
    }

    $cache[$uid] = 'Unknown';
    return 'Unknown';
}

// Build a clean display token/number
function getEntryNumber(array $e): string {
    // You don't have queueNumber in your entry docs, but you DO have id "ENTRY_<uid>"
    if (!empty($e['queueNumber'])) {
        return (string)$e['queueNumber'];
    }

    if (!empty($e['id']) && is_string($e['id'])) {
        // show a shorter token instead of full UID
        $id = $e['id'];
        $id = str_replace('ENTRY_', '', $id);
        return $id;
    }

    return '?';
}

$flash = $_SESSION['flash'] ?? null;
unset($_SESSION['flash']);
?>

<div class="page-header">
  <div class="page-header-top">
    <div>
      <h1 class="page-title">📋 Queue Management</h1>
      <p class="page-subtitle">Manage queues across all services</p>
    </div>
    <div class="header-actions">
      <button class="btn btn-secondary" onclick="location.reload()">↻ Refresh</button>
    </div>
  </div>
</div>

<?php if ($flash): ?>
  <div class="alert alert-<?= h($flash['type'] ?? 'info') ?>">
    <?= h($flash['message'] ?? '') ?>
  </div>
<?php endif; ?>

<?php if ($error): ?>
  <div class="alert alert-danger">Failed to load services: <?= h($error) ?></div>
<?php endif; ?>

<div style="display:grid; gap: var(--spacing-xl);">

<?php if (!empty($services)): ?>
  <?php foreach ($services as $service): ?>
    <?php
      $sData = $service->data();
      $serviceId = $service->id();

      $entriesError = null;
      $pendingEntries = [];
      $activeEntries = [];

      try {
          $all = $firestore
              ->collection("services/$serviceId/entries")
              ->orderBy('joinedAt')
              ->limit(50)
              ->documents();

          foreach ($all as $entry) {
              $e = $entry->data();
              $status = $e['status'] ?? 'pending';
              if ($status === 'active') $activeEntries[] = $entry;
              else $pendingEntries[] = $entry;
          }
      } catch (Throwable $e) {
          $entriesError = $e->getMessage();
          error_log("Queue entries load error ($serviceId): " . $e->getMessage());
      }

      $isOpen = (bool)($sData['isOpen'] ?? false);
      $pendingCount = (int)($sData['pendingCount'] ?? 0);
      $activeCount  = (int)($sData['activeCount'] ?? 0);
    ?>

    <div class="card">
      <div class="card-header" style="display:flex; justify-content:space-between; align-items:flex-start; gap:1rem;">
        <div>
          <h2 class="card-title"><?= h($sData['name'] ?? 'Unknown Service') ?></h2>
          <div style="margin-top:.5rem; display:flex; flex-wrap:wrap; gap:.5rem;">
            <span class="badge <?= $isOpen ? 'badge-success' : 'badge-danger' ?>">
              <?= $isOpen ? 'Open' : 'Closed' ?>
            </span>
            <span class="badge badge-info"><?= $pendingCount ?> Pending</span>
            <span class="badge badge-warning"><?= $activeCount ?> Active</span>
          </div>
        </div>

        <div style="display:flex; gap:.5rem;">
          <!-- Call Next (AJAX) -->
          <form method="POST"
                data-ajax
                action="<?= BASE_PATH ?>/api/queue_call_next.php"
                style="margin:0;">
            <input type="hidden" name="csrf_token" value="<?= h(generateCSRFToken()); ?>">
            <input type="hidden" name="serviceId" value="<?= h($serviceId); ?>">
            <button class="btn btn-primary" type="submit" <?= !$isOpen ? 'disabled' : '' ?>>
              📢 Call Next
            </button>
          </form>
        </div>
      </div>

      <div class="card-body">

        <?php if ($entriesError): ?>
          <div class="alert alert-danger">Error loading queue: <?= h($entriesError) ?></div>
        <?php else: ?>

          <!-- Pending -->
          <div style="margin-bottom:1rem;">
            <h3 style="margin:0 0 .75rem 0; font-size:1rem; color:var(--text);">
              ⏳ Pending (<?= count($pendingEntries) ?>)
            </h3>

            <?php if (empty($pendingEntries)): ?>
              <div style="padding:1rem; color:var(--text-muted);">No pending entries</div>
            <?php else: ?>
              <?php foreach ($pendingEntries as $entry): ?>
                <?php
                  $e = $entry->data();
                  $entryId = $entry->id();

                  // ✅ Your structure uses userId / tempUserKey
                  $uid = $e['userId'] ?? ($e['tempUserKey'] ?? null);

                  // Prefer stored displayName, else fetch users/{uid}.name, else email
                  $student = $e['userDisplayName'] ?? null;
                  if (!is_string($student) || trim($student) === '' || strtolower($student) === 'null') {
                      $student = getUserNameByUid($firestore, $uid, $userNameCache);
                  }
                  if ($student === 'Unknown') {
                      $student = (is_string($e['userEmail'] ?? null) && $e['userEmail'] !== '')
                          ? $e['userEmail']
                          : 'Unknown';
                  }

                  $number = getEntryNumber($e);
                ?>
                <div class="queue-entry" style="display:flex; justify-content:space-between; align-items:center; padding:.75rem 0; border-bottom:1px solid var(--glass-border);">
                  <div>
                    <strong><?= h($student) ?></strong>
                    <span style="color:var(--text-muted); margin-left:.5rem;">#<?= h($number) ?></span>
                  </div>

                  <div style="display:flex; gap:.5rem;">
                    <span class="badge badge-warning">Pending</span>

                    <!-- Delete (AJAX) -->
                    <form method="POST"
                          data-ajax
                          action="<?= BASE_PATH ?>/api/queue_delete.php"
                          style="margin:0;"
                          onsubmit="return confirm('Remove this entry?');">
                      <input type="hidden" name="csrf_token" value="<?= h(generateCSRFToken()); ?>">
                      <input type="hidden" name="serviceId" value="<?= h($serviceId); ?>">
                      <input type="hidden" name="entryId" value="<?= h($entryId); ?>">
                      <button class="btn btn-sm btn-danger" type="submit">🗑️</button>
                    </form>
                  </div>
                </div>
              <?php endforeach; ?>
            <?php endif; ?>
          </div>

          <!-- Active -->
          <div>
            <h3 style="margin:0 0 .75rem 0; font-size:1rem; color:var(--text);">
              ✅ Active (<?= count($activeEntries) ?>)
            </h3>

            <?php if (empty($activeEntries)): ?>
              <div style="padding:1rem; color:var(--text-muted);">No active entries</div>
            <?php else: ?>
              <?php foreach ($activeEntries as $entry): ?>
                <?php
                  $e = $entry->data();
                  $entryId = $entry->id();

                  $uid = $e['userId'] ?? ($e['tempUserKey'] ?? null);

                  $student = $e['userDisplayName'] ?? null;
                  if (!is_string($student) || trim($student) === '' || strtolower($student) === 'null') {
                      $student = getUserNameByUid($firestore, $uid, $userNameCache);
                  }
                  if ($student === 'Unknown') {
                      $student = (is_string($e['userEmail'] ?? null) && $e['userEmail'] !== '')
                          ? $e['userEmail']
                          : 'Unknown';
                  }

                  $number = getEntryNumber($e);
                ?>
                <div class="queue-entry" style="display:flex; justify-content:space-between; align-items:center; padding:.75rem 0; border-bottom:1px solid var(--glass-border);">
                  <div>
                    <strong><?= h($student) ?></strong>
                    <span style="color:var(--text-muted); margin-left:.5rem;">#<?= h($number) ?></span>
                  </div>

                  <div style="display:flex; gap:.5rem;">
                    <span class="badge badge-success">Active</span>

                    <!-- Serve (AJAX) -->
                    <form method="POST"
                          data-ajax
                          action="<?= BASE_PATH ?>/api/queue_serve.php"
                          style="margin:0;">
                      <input type="hidden" name="csrf_token" value="<?= h(generateCSRFToken()); ?>">
                      <input type="hidden" name="serviceId" value="<?= h($serviceId); ?>">
                      <input type="hidden" name="entryId" value="<?= h($entryId); ?>">
                      <button class="btn btn-sm btn-success" type="submit">Serve</button>
                    </form>

                    <!-- Delete (AJAX) -->
                    <form method="POST"
                          data-ajax
                          action="<?= BASE_PATH ?>/api/queue_delete.php"
                          style="margin:0;"
                          onsubmit="return confirm('Remove this entry?');">
                      <input type="hidden" name="csrf_token" value="<?= h(generateCSRFToken()); ?>">
                      <input type="hidden" name="serviceId" value="<?= h($serviceId); ?>">
                      <input type="hidden" name="entryId" value="<?= h($entryId); ?>">
                      <button class="btn btn-sm btn-danger" type="submit">🗑️</button>
                    </form>
                  </div>
                </div>
              <?php endforeach; ?>
            <?php endif; ?>
          </div>

        <?php endif; ?>
      </div>
    </div>

  <?php endforeach; ?>
<?php endif; ?>

</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
