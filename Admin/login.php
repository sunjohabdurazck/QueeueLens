<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - QueueLens Admin</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <style>
        .login-container {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: var(--spacing-xl);
        }
        
        .login-box {
            width: 100%;
            max-width: 450px;
        }
        
        .login-header {
            text-align: center;
            margin-bottom: var(--spacing-xl);
        }
        
        .login-logo {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            border-radius: var(--radius-xl);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 2.5rem;
            margin-bottom: var(--spacing-lg);
            box-shadow: var(--shadow-glow);
            animation: float 3s ease-in-out infinite;
        }
        
        @keyframes float {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-10px); }
        }
        
        .login-title {
            font-size: 2rem;
            font-weight: 700;
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: var(--spacing-sm);
        }
        
        .login-subtitle {
            color: var(--text-secondary);
        }
        
        .login-card {
            background: var(--glass-bg);
            backdrop-filter: blur(20px);
            border: 1px solid var(--glass-border);
            border-radius: var(--radius-xl);
            padding: var(--spacing-xl);
            box-shadow: var(--shadow-xl);
        }
        
        .input-group {
            position: relative;
            margin-bottom: var(--spacing-lg);
        }
        
        .input-icon {
            position: absolute;
            left: var(--spacing-md);
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-muted);
            font-size: 1.25rem;
        }
        
        .input-with-icon {
            padding-left: 3rem;
        }
        
        .toggle-password {
            position: absolute;
            right: var(--spacing-md);
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            color: var(--text-muted);
            cursor: pointer;
            font-size: 1.25rem;
            transition: color var(--transition-fast);
        }
        
        .toggle-password:hover {
            color: var(--text-primary);
        }
        
        .remember-forgot {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: var(--spacing-lg);
        }
        
        .checkbox-label {
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            cursor: pointer;
            color: var(--text-secondary);
        }
        
        .checkbox-label input[type="checkbox"] {
            width: 18px;
            height: 18px;
            cursor: pointer;
        }
        
        .forgot-link {
            color: var(--primary-color);
            text-decoration: none;
            font-size: 0.875rem;
            transition: color var(--transition-fast);
        }
        
        .forgot-link:hover {
            color: var(--primary-light);
        }
        
        .login-footer {
            text-align: center;
            margin-top: var(--spacing-xl);
            color: var(--text-muted);
            font-size: 0.875rem;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="login-box">
            <div class="login-header">
                <div class="login-logo">🎯</div>
                <h1 class="login-title">QueueLens</h1>
                <p class="login-subtitle">Admin & Staff Portal</p>
            </div>
            
            <div class="login-card">
                <?php if (isset($_GET['error'])): ?>
                    <div class="alert alert-danger">
                        <span>⚠</span>
                        <span>Invalid credentials. Please try again.</span>
                    </div>
                <?php endif; ?>
                
                <?php if (isset($_GET['logout'])): ?>
                    <div class="alert alert-success">
                        <span>✓</span>
                        <span>You have been logged out successfully.</span>
                    </div>
                <?php endif; ?>
                
                <form method="POST" action="/queuelens/api/login.php">
                    <div class="input-group">
                        <span class="input-icon">📧</span>
                        <input 
                            type="email" 
                            name="email" 
                            class="form-input input-with-icon" 
                            placeholder="Email address"
                            required
                            autofocus
                        >
                    </div>
                    
                    <div class="input-group">
                        <span class="input-icon">🔒</span>
                        <input 
                            type="password" 
                            name="password" 
                            id="password"
                            class="form-input input-with-icon" 
                            placeholder="Password"
                            required
                        >
                        <button type="button" class="toggle-password" onclick="togglePassword()">
                            👁️
                        </button>
                    </div>
                    
                    <div class="remember-forgot">
                        <label class="checkbox-label">
                            <input type="checkbox" name="remember">
                            <span>Remember me</span>
                        </label>
                        <a href="#" class="forgot-link">Forgot password?</a>
                    </div>
                    
                    <button type="submit" class="btn btn-primary btn-lg" style="width: 100%;">
                        <span>Sign In</span>
                        <span>→</span>
                    </button>
                </form>
            </div>
            
            <div class="login-footer">
                <p>QueueLens Admin v1.0</p>
                <p style="margin-top: var(--spacing-sm);">
                    <span class="status-dot online"></span>
                    System Online
                </p>
            </div>
        </div>
    </div>
    
    <script>
        function togglePassword() {
            const passwordInput = document.getElementById('password');
            const type = passwordInput.type === 'password' ? 'text' : 'password';
            passwordInput.type = type;
        }
        
        // Add floating particles
        function createParticle() {
            const particle = document.createElement('div');
            particle.style.cssText = `
                position: fixed;
                width: 4px;
                height: 4px;
                background: rgba(99, 102, 241, 0.5);
                border-radius: 50%;
                pointer-events: none;
                z-index: -1;
                left: ${Math.random() * 100}vw;
                top: 100vh;
                animation: float-up ${5 + Math.random() * 5}s linear forwards;
            `;
            document.body.appendChild(particle);
            
            setTimeout(() => particle.remove(), 10000);
        }
        
        const style = document.createElement('style');
        style.textContent = `
            @keyframes float-up {
                to {
                    transform: translateY(-120vh) translateX(${Math.random() * 100 - 50}px);
                    opacity: 0;
                }
            }
        `;
        document.head.appendChild(style);
        
        setInterval(createParticle, 500);
    </script>
</body>
</html>
