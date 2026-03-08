<?php
if (session_status() === PHP_SESSION_NONE) session_start();
$currentPage = basename($_SERVER['PHP_SELF']);
$currentDir  = basename(dirname($_SERVER['PHP_SELF']));
$isAdmin     = isset($_SESSION['user_role']) && $_SESSION['user_role'] === 'admin';
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>QueueLens — <?= htmlspecialchars($pageTitle ?? 'Admin') ?></title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="color-scheme" content="light dark">
<script src="<?= BASE_PATH ?>/assets/js/theme.js"></script>
<link rel="stylesheet" href="<?= BASE_PATH ?>/assets/css/style.css">
</head>
<body>
<div class="app-container">
<aside class="sidebar" id="sidebar">
  <div class="sidebar-header">
    <a href="<?= BASE_PATH ?>/index.php" class="sidebar-logo">
      <div class="logo-icon">⚡</div>
      <div>
        <div class="logo-text">QueueLens</div>
        <div class="logo-version">ADMIN v3.0</div>
      </div>
    </a>
  </div>
  <div class="sidebar-user">
    <div class="sidebar-avatar"><?= strtoupper(substr($_SESSION['user_name'] ?? 'A', 0, 1)) ?></div>
    <div style="flex:1;min-width:0">
      <div class="sidebar-user-name"><?= htmlspecialchars($_SESSION['user_name'] ?? 'Admin') ?></div>
      <span class="sidebar-user-role <?= htmlspecialchars($_SESSION['user_role'] ?? 'staff') ?>"><?= ucfirst($_SESSION['user_role'] ?? 'staff') ?></span>
    </div>
  </div>
  <nav class="sidebar-nav">
    <div class="nav-section-label">Operations</div>
    <a href="<?= BASE_PATH ?>/index.php" class="sidebar-nav-link <?= $currentPage==='index.php'?'active':'' ?>">
      <span class="nav-icon">📊</span> Dashboard
    </a>
    <a href="<?= BASE_PATH ?>/pages/queue.php" class="sidebar-nav-link <?= $currentPage==='queue.php'?'active':'' ?>">
      <span class="nav-icon">📋</span> Live Queue
    </a>
    <a href="<?= BASE_PATH ?>/pages/services.php" class="sidebar-nav-link <?= $currentPage==='services.php'?'active':'' ?>">
      <span class="nav-icon">🏢</span> Services
    </a>
    <a href="<?= BASE_PATH ?>/pages/cameras.php" class="sidebar-nav-link <?= $currentPage==='cameras.php'?'active':'' ?>">
      <span class="nav-icon">📹</span> Cameras
    </a>
    <div class="nav-section-label">People</div>
    <a href="<?= BASE_PATH ?>/pages/users.php" class="sidebar-nav-link <?= $currentPage==='users.php'?'active':'' ?>">
      <span class="nav-icon">👥</span> Staff &amp; Users
    </a>
    <?php if ($isAdmin): ?>
    <div class="nav-section-label">Admin</div>
    <a href="<?= BASE_PATH ?>/pages/analytics.php" class="sidebar-nav-link <?= $currentPage==='analytics.php'?'active':'' ?>">
      <span class="nav-icon">📈</span> Analytics
    </a>
    <a href="<?= BASE_PATH ?>/pages/alerts.php" class="sidebar-nav-link <?= $currentPage==='alerts.php'?'active':'' ?>">
      <span class="nav-icon">🔔</span> Alerts
    </a>
    <a href="<?= BASE_PATH ?>/pages/logs.php" class="sidebar-nav-link <?= $currentPage==='logs.php'?'active':'' ?>">
      <span class="nav-icon">📝</span> Audit Logs
    </a>
    <?php endif; ?>
    <div class="theme-switcher-card">
      <div class="theme-switcher-title">Theme <span data-theme-current-label>System</span></div>
      <div class="theme-switcher" role="group" aria-label="Choose theme">
        <button type="button" class="theme-btn" data-theme-option="light" aria-pressed="false">☀️ Light</button>
        <button type="button" class="theme-btn" data-theme-option="dark" aria-pressed="false">🌙 Dark</button>
        <button type="button" class="theme-btn" data-theme-option="system" aria-pressed="false">💻 System</button>
      </div>
    </div>
    <div style="margin-top:auto;padding-top:16px;border-top:1px solid var(--c-border);margin-top:20px">
      <a href="<?= BASE_PATH ?>/api/logout.php" class="sidebar-nav-link">
        <span class="nav-icon">🚪</span> Logout
      </a>
    </div>
  </nav>
</aside>
<main class="main-content">
<div class="toast-container" id="toastContainer"></div>
