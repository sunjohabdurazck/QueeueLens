<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>QueueLens Admin</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <!-- ✅ MAIN ADMIN STYLES -->
    <link rel="stylesheet" href="<?= BASE_PATH ?>/assets/css/style.css">

    <!-- ✅ GOOGLE FONT (Inter) -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

    <!-- ✅ ICONS (Emoji-safe fallback, optional later) -->
</head>

<body>
    <div class="app-container">
        <aside class="sidebar">
            <div class="sidebar-header">
                <a href="<?php echo BASE_URL; ?>" class="sidebar-logo">
                    <div class="logo-icon">🎯</div>
                    <span>QueueLens</span>
                </a>
            </div>
            
            <nav>
                <ul class="sidebar-nav">
                    <li class="sidebar-nav-item">
                        <a href="<?php echo BASE_URL; ?>/index.php" class="sidebar-nav-link">
                            <span class="sidebar-nav-icon">📊</span>
                            <span>Dashboard</span>
                        </a>
                    </li>
                    <li class="sidebar-nav-item">
                        <a href="<?php echo BASE_URL; ?>/pages/cameras.php" class="sidebar-nav-link">
                            <span class="sidebar-nav-icon">📹</span>
                            <span>Cameras</span>
                        </a>
                    </li>
                    <li class="sidebar-nav-item">
                        <a href="<?php echo BASE_URL; ?>/pages/services.php" class="sidebar-nav-link">
                            <span class="sidebar-nav-icon">🏢</span>
                            <span>Services</span>
                        </a>
                    </li>
                    <li class="sidebar-nav-item">
                        <a href="<?php echo BASE_URL; ?>/pages/queue.php" class="sidebar-nav-link">
                            <span class="sidebar-nav-icon">📋</span>
                            <span>Queue Management</span>
                        </a>
                    </li>
                    <li class="sidebar-nav-item">
                        <a href="<?php echo BASE_URL; ?>/pages/3d-map.php" class="sidebar-nav-link">
                            <span class="sidebar-nav-icon">🗺️</span>
                            <span>3D Campus Map</span>
                        </a>
                    </li>
                    <?php if (hasRole(ROLE_ADMIN)): ?>
                    <li class="sidebar-nav-item">
                        <a href="<?php echo BASE_URL; ?>/pages/users.php" class="sidebar-nav-link">
                            <span class="sidebar-nav-icon">👥</span>
                            <span>Users & Roles</span>
                        </a>
                    </li>
                    <?php endif; ?>
                    <li class="sidebar-nav-item">
                        <a href="<?php echo BASE_URL; ?>/pages/analytics.php" class="sidebar-nav-link">
                            <span class="sidebar-nav-icon">📈</span>
                            <span>Analytics</span>
                        </a>
                    </li>
                    <li class="sidebar-nav-item">
                        <a href="<?php echo BASE_URL; ?>/pages/logs.php" class="sidebar-nav-link">
                            <span class="sidebar-nav-icon">📝</span>
                            <span>Logs</span>
                        </a>
                    </li>
                    <li class="sidebar-nav-item" style="margin-top: auto; padding-top: 2rem; border-top: 1px solid var(--glass-border);">
                        <a href="<?php echo BASE_URL; ?>/api/logout.php" class="sidebar-nav-link">
                            <span class="sidebar-nav-icon">🚪</span>
                            <span>Logout</span>
                        </a>
                    </li>
                </ul>
            </nav>
        </aside>
        
        <main class="main-content">
