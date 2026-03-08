<?php
ini_set('display_errors', 0);
error_reporting(0);

if (session_status() === PHP_SESSION_NONE) session_start();

require_once 'config/config.php';

if (isAuthenticated()) { redirectTo('index.php'); }

$error = errorMessageFromQuery();
$csrfToken = generateCSRFToken();

// Load public Firebase client config
$fcPath = __DIR__ . '/config/firebase_client.json';
$firebaseConfig = file_exists($fcPath) ? json_decode(file_get_contents($fcPath), true) : [];
if (!$firebaseConfig) {
    $firebaseConfig = [
        'apiKey'            => getenv('FIREBASE_API_KEY') ?: 'REPLACE_ME',
        'authDomain'        => getenv('FIREBASE_AUTH_DOMAIN') ?: 'REPLACE_ME',
        'projectId'         => getenv('FIREBASE_PROJECT_ID') ?: 'REPLACE_ME',
        'storageBucket'     => getenv('FIREBASE_STORAGE_BUCKET') ?: '',
        'messagingSenderId' => getenv('FIREBASE_MESSAGING_SENDER_ID') ?: '',
        'appId'             => getenv('FIREBASE_APP_ID') ?: '',
    ];
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>QueueLens — Sign In</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="color-scheme" content="light dark">
<script src="<?= BASE_PATH ?>/assets/js/theme.js"></script>
<link rel="stylesheet" href="<?= BASE_PATH ?>/assets/css/style.css">
</head>
<body>
<div class="login-page">
  <div class="login-theme-toolbar">
    <button type="button" class="theme-btn" data-theme-option="light" aria-pressed="false">☀️ Light</button>
    <button type="button" class="theme-btn" data-theme-option="dark" aria-pressed="false">🌙 Dark</button>
    <button type="button" class="theme-btn" data-theme-option="system" aria-pressed="false">💻 System</button>
  </div>
  <div class="login-card">
    <div class="login-logo">
      <div class="login-logo-icon">⚡</div>
      <div>
        <div class="login-title">QueueLens</div>
        <div class="login-subtitle">Admin &amp; Staff Portal</div>
      </div>
    </div>

    <?php if ($error): ?>
    <div class="alert alert-danger" style="margin-bottom:20px">⚠️ <?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    <div id="authErrorMsg" class="alert alert-danger" style="display:none;margin-bottom:20px"></div>

    <div class="alert alert-info" style="margin-bottom:24px;font-size:.78rem">
      🔒 Sign in with your registered staff or admin Firebase account.
    </div>

    <div class="form-group">
      <label class="form-label" for="email">Email address</label>
      <input class="form-control" type="email" id="email" required
             placeholder="you@university.edu" autocomplete="email">
    </div>

    <div class="form-group">
      <label class="form-label" for="password">Password</label>
      <input class="form-control" type="password" id="password" required
             placeholder="••••••••" autocomplete="current-password">
      <div class="form-hint">Your Firebase account password</div>
    </div>

    <button class="btn btn-primary w-full btn-lg" id="loginBtn" onclick="doFirebaseLogin()">
      <span id="loginSpinner" class="spinner" style="display:none"></span>
      Sign In
    </button>

    <!-- Hidden form: only submitted after Firebase confirms credentials -->
    <form method="POST" action="<?= BASE_PATH ?>/api/login.php" id="loginForm" style="display:none">
      <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
      <input type="hidden" name="id_token" id="idTokenInput">
    </form>

    <div style="margin-top:24px;text-align:center">
      <p style="font-size:.72rem;color:var(--c-text3)">
        Only staff and admin accounts can access this portal.<br>
        Students: use the QueueLens mobile app.
      </p>
    </div>
  </div>
</div>

<script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-auth-compat.js"></script>
<script>
firebase.initializeApp(<?= json_encode($firebaseConfig) ?>);
const auth = firebase.auth();

// Add debug listener for auth state changes
auth.onAuthStateChanged((user) => {
  if (user) {
    console.log('Auth state changed: User signed in:', user.email);
  } else {
    console.log('Auth state changed: No user signed in');
  }
});

async function doFirebaseLogin() {
  const email    = document.getElementById('email').value.trim();
  const password = document.getElementById('password').value;
  const btn      = document.getElementById('loginBtn');
  const spinner  = document.getElementById('loginSpinner');

  hideError();
  if (!email || !password) { showError('Please enter your email and password.'); return; }

  btn.disabled = true;
  spinner.style.display = 'inline-block';

  try {
    console.log('Attempting Firebase login for:', email);
    const cred    = await auth.signInWithEmailAndPassword(email, password);
    console.log('Firebase login successful, getting ID token...');
    const idToken = await cred.user.getIdToken(true);
    console.log('ID token obtained, submitting form...');
    document.getElementById('idTokenInput').value = idToken;
    document.getElementById('loginForm').submit();
  } catch (err) {
    // TEMPORARY DEBUGGING CODE - Shows actual Firebase errors
    console.error('Firebase login error:', err);
    console.error('Error code:', err.code);
    console.error('Error message:', err.message);
    console.error('Full error object:', JSON.stringify(err, Object.getOwnPropertyNames(err)));
    
    btn.disabled = false;
    spinner.style.display = 'none';
    showError((err.code || 'unknown') + ' — ' + (err.message || 'Sign-in failed'));
  }
}

function showError(msg) {
  const el = document.getElementById('authErrorMsg');
  el.textContent = '⚠️ ' + msg;
  el.style.display = 'block';
  console.log('Showing error to user:', msg);
}

function hideError() {
  document.getElementById('authErrorMsg').style.display = 'none';
}

document.addEventListener('keydown', e => { if (e.key === 'Enter') doFirebaseLogin(); });

// Log the Firebase config being used (without sensitive data)
console.log('Firebase initialized with config:', {
  ...<?= json_encode($firebaseConfig) ?>,
  apiKey: '***hidden***'
});
</script>
</body>
</html>