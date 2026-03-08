/**
 * Queue Master Admin - Main JavaScript
 * Version 2.0
 */

class AdminApp {
    constructor() {
        this.initializeApp();
    }

    initializeApp() {
        this.setupEventListeners();
        this.initializeModals();
        this.initializeNotifications();
        this.startRealTimeUpdates();
    }

    setupEventListeners() {
        // Mobile menu toggle
        const menuToggle = document.querySelector('.menu-toggle');
        const sidebar = document.querySelector('.sidebar');
        
        if (menuToggle) {
            menuToggle.addEventListener('click', () => {
                sidebar.classList.toggle('active');
            });
        }

        // Close sidebar on outside click (mobile)
        document.addEventListener('click', (e) => {
            if (window.innerWidth <= 768) {
                if (!sidebar.contains(e.target) && !menuToggle.contains(e.target)) {
                    sidebar.classList.remove('active');
                }
            }
        });

        // Form submissions
        document.querySelectorAll('form[data-ajax]').forEach(form => {
            form.addEventListener('submit', (e) => this.handleAjaxForm(e));
        });

        // Delete confirmations
        document.querySelectorAll('[data-confirm]').forEach(btn => {
            btn.addEventListener('click', (e) => this.handleConfirm(e));
        });
    }

    initializeModals() {
        // Close modal on overlay click
        document.querySelectorAll('.modal-overlay').forEach(overlay => {
            overlay.addEventListener('click', (e) => {
                if (e.target === overlay) {
                    this.closeModal(overlay);
                }
            });
        });

        // Close modal buttons
        document.querySelectorAll('.modal-close, [data-modal-close]').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const modal = e.target.closest('.modal-overlay');
                this.closeModal(modal);
            });
        });

        // Open modal buttons
        document.querySelectorAll('[data-modal]').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                const modalId = btn.dataset.modal;
                this.openModal(modalId);
            });
        });
    }

    openModal(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.add('active');
            document.body.style.overflow = 'hidden';
        }
    }

    closeModal(modal) {
        if (modal) {
            modal.classList.remove('active');
            document.body.style.overflow = '';
        }
    }

    initializeNotifications() {
        this.notificationContainer = document.getElementById('notifications');
        if (!this.notificationContainer) {
            this.notificationContainer = document.createElement('div');
            this.notificationContainer.id = 'notifications';
            this.notificationContainer.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                z-index: 10000;
                max-width: 400px;
            `;
            document.body.appendChild(this.notificationContainer);
        }
    }

    showNotification(message, type = 'info', duration = 5000) {
        const notification = document.createElement('div');
        notification.className = `alert alert-${type}`;
        notification.style.cssText = `
            animation: slideInRight 0.3s ease-out;
            margin-bottom: 1rem;
            box-shadow: 0 10px 25px rgba(0,0,0,0.3);
        `;
        
        const icons = {
            success: '✓',
            danger: '✕',
            warning: '⚠',
            info: 'ℹ'
        };
        
        notification.innerHTML = `
            <div style="display: flex; align-items: center; gap: 1rem;">
                <span style="font-size: 1.5rem;">${icons[type] || 'ℹ'}</span>
                <span>${message}</span>
            </div>
        `;
        
        this.notificationContainer.appendChild(notification);
        
        setTimeout(() => {
            notification.style.animation = 'slideOutRight 0.3s ease-out';
            setTimeout(() => notification.remove(), 300);
        }, duration);
    }

    async handleAjaxForm(e) {
  e.preventDefault();

  // In case the submit event came from a button/input, find the closest form
  const form = e.target.tagName === 'FORM' ? e.target : e.target.closest('form');

  if (!form) {
    console.error('handleAjaxForm: No form found for event target:', e.target);
    this.showNotification('No form found (JS binding issue).', 'danger', 9000);
    return;
  }

  // Always read from attribute, NOT from form.action property
  let url = form.getAttribute('action');

  // Debug logs
  console.log('AJAX SUBMIT target:', e.target);
  console.log('AJAX SUBMIT form:', form);
  console.log('AJAX SUBMIT action attribute:', url);

  // If missing/invalid, fallback
  if (!url || url === '#' || url.includes('[object')) {
    console.error('Invalid form action attribute:', url);
    this.showNotification('Form action is missing/invalid. Check HTML action="...".', 'danger', 9000);
    return;
  }

  // Make absolute URL
  url = new URL(url, window.location.origin).toString();

  const formData = new FormData(form);
  const method = (form.getAttribute('method') || 'POST').toUpperCase();

  try {
    const response = await fetch(url, {
      method,
      body: formData,
      headers: { 'X-Requested-With': 'XMLHttpRequest' }
    });

    const raw = await response.text();

    let data = null;
    try { data = JSON.parse(raw); } catch (_) {}

    if (!response.ok) {
      console.error('Server response (non-OK):', raw);
      this.showNotification(data?.message || raw.slice(0, 200), 'danger', 9000);
      return;
    }

    if (!data) {
      console.error('Non-JSON response:', raw);
      this.showNotification('Server did not return JSON. Check console.', 'danger', 9000);
      return;
    }

    if (data.success) {
      this.showNotification(data.message || 'Success', 'success');
      const modal = form.closest('.modal-overlay');
      if (modal) this.closeModal(modal);
      if (data.reload) setTimeout(() => location.reload(), 600);
      form.reset();
    } else {
      this.showNotification(data.message || 'Operation failed', 'danger', 9000);
    }

  } catch (err) {
    console.error('Fetch error:', err);
    this.showNotification('Network/JS error: ' + err.message, 'danger', 9000);
  }
}



    handleConfirm(e) {
        const message = e.target.dataset.confirm || 'Are you sure?';
        if (!confirm(message)) {
            e.preventDefault();
        }
    }

    startRealTimeUpdates() {
        // Update timestamps
        this.updateTimestamps();
        setInterval(() => this.updateTimestamps(), 60000); // Every minute

        // Refresh stats
        if (document.querySelector('.stats-grid')) {
            this.refreshStats();
            setInterval(() => this.refreshStats(), 30000); // Every 30 seconds
        }
    }

    updateTimestamps() {
        document.querySelectorAll('[data-timestamp]').forEach(el => {
            const timestamp = parseInt(el.dataset.timestamp);
            el.textContent = this.formatRelativeTime(timestamp);
        });
    }

    formatRelativeTime(timestamp) {
        const now = Date.now();
        const diff = now - (timestamp * 1000);
        const seconds = Math.floor(diff / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);

        if (days > 0) return `${days}d ago`;
        if (hours > 0) return `${hours}h ago`;
        if (minutes > 0) return `${minutes}m ago`;
        return 'Just now';
    }

    async refreshStats() {
        try {
            const response = await fetch('/queuelens/api/stats.php');
            const data = await response.json();
            
            if (data.success) {
                this.updateStatCards(data.stats);
            }
        } catch (error) {
            console.error('Stats refresh error:', error);
        }
    }

    updateStatCards(stats) {
        Object.keys(stats).forEach(key => {
            const element = document.querySelector(`[data-stat="${key}"]`);
            if (element) {
                this.animateValue(element, parseInt(element.textContent), stats[key], 1000);
            }
        });
    }

    animateValue(element, start, end, duration) {
        const range = end - start;
        const increment = range / (duration / 16);
        let current = start;

        const timer = setInterval(() => {
            current += increment;
            if ((increment > 0 && current >= end) || (increment < 0 && current <= end)) {
                element.textContent = end;
                clearInterval(timer);
            } else {
                element.textContent = Math.round(current);
            }
        }, 16);
    }
}

// Camera Stream Manager
class CameraStreamManager {
    constructor() {
        this.streams = new Map();
    }

    async testStream(cameraId, streamUrl) {
        try {
            const response = await fetch(`/api/stream-test.php?url=${encodeURIComponent(streamUrl)}`);
            const data = await response.json();
            return data.success;
        } catch (error) {
            console.error('Stream test error:', error);
            return false;
        }
    }

    loadStream(elementId, streamUrl, type) {
        const element = document.getElementById(elementId);
        if (!element) return;

        switch(type) {
            case 0: // MJPEG
                element.innerHTML = `<img src="${streamUrl}" style="width: 100%; height: auto;" alt="Camera Stream">`;
                break;
            case 1: // RTSP (requires conversion)
                element.innerHTML = `<video src="${streamUrl}" autoplay muted style="width: 100%; height: auto;"></video>`;
                break;
            case 2: // HLS
                this.loadHLS(element, streamUrl);
                break;
            case 3: // WebRTC
                this.loadWebRTC(element, streamUrl);
                break;
        }
    }

    loadHLS(element, url) {
        if (Hls.isSupported()) {
            const hls = new Hls();
            const video = document.createElement('video');
            video.controls = true;
            video.style.width = '100%';
            hls.loadSource(url);
            hls.attachMedia(video);
            element.appendChild(video);
        }
    }

    loadWebRTC(element, url) {
        // WebRTC implementation would go here
        element.innerHTML = `<p>WebRTC stream: ${url}</p>`;
    }

    stopStream(elementId) {
        const element = document.getElementById(elementId);
        if (element) {
            element.innerHTML = '';
        }
    }
}

// Queue Manager
class QueueManager {
    async callNext(serviceId) {
        try {
            const response = await fetch('/api/queue-actions.php', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    action: 'call_next',
                    serviceId: serviceId
                })
            });
            
            const data = await response.json();
            
            if (data.success) {
                app.showNotification('Next person called successfully', 'success');
                this.refreshQueue(serviceId);
            } else {
                app.showNotification(data.message || 'Failed to call next', 'danger');
            }
        } catch (error) {
            console.error('Call next error:', error);
            app.showNotification('An error occurred', 'danger');
        }
    }

    async markServed(entryId, serviceId) {
        try {
            const response = await fetch('/api/queue-actions.php', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    action: 'mark_served',
                    entryId: entryId,
                    serviceId: serviceId
                })
            });
            
            const data = await response.json();
            
            if (data.success) {
                app.showNotification('Entry marked as served', 'success');
                this.refreshQueue(serviceId);
            } else {
                app.showNotification(data.message || 'Failed to mark as served', 'danger');
            }
        } catch (error) {
            console.error('Mark served error:', error);
            app.showNotification('An error occurred', 'danger');
        }
    }

    async refreshQueue(serviceId) {
        const queueContainer = document.getElementById(`queue-${serviceId}`);
        if (!queueContainer) return;

        try {
            const response = await fetch(`/api/get-queue.php?serviceId=${serviceId}`);
            const data = await response.json();
            
            if (data.success) {
                this.renderQueue(queueContainer, data.entries);
            }
        } catch (error) {
            console.error('Refresh queue error:', error);
        }
    }

    renderQueue(container, entries) {
        container.innerHTML = entries.map(entry => `
            <div class="queue-entry" data-entry-id="${entry.id}">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <strong>${entry.studentName || 'Unknown'}</strong>
                        <span class="text-muted">#${entry.queueNumber}</span>
                    </div>
                    <div>
                        <span class="badge badge-${entry.status === 'active' ? 'success' : 'warning'}">
                            ${entry.status}
                        </span>
                        <button class="btn btn-sm btn-success" onclick="queueManager.markServed('${entry.id}', '${entry.serviceId}')">
                            Serve
                        </button>
                    </div>
                </div>
            </div>
        `).join('');
    }
}

// 3D Campus Map
class CampusMap3D {
    constructor(canvasId) {
        this.canvas = document.getElementById(canvasId);
        if (!this.canvas) return;
        
        this.ctx = this.canvas.getContext('2d');
        this.cameras = [];
        this.services = [];
        this.selectedCamera = null;
        
        this.init();
    }

    init() {
        this.canvas.width = this.canvas.offsetWidth;
        this.canvas.height = this.canvas.offsetHeight;
        
        this.canvas.addEventListener('click', (e) => this.handleClick(e));
        this.canvas.addEventListener('mousemove', (e) => this.handleMouseMove(e));
        
        this.render();
    }

    setCameras(cameras) {
        this.cameras = cameras;
        this.render();
    }

    setServices(services) {
        this.services = services;
        this.render();
    }

    handleClick(e) {
        const rect = this.canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        
        // Check if clicked on camera
        this.cameras.forEach(camera => {
            const screenPos = this.project3DTo2D(camera.position);
            const distance = Math.sqrt(
                Math.pow(x - screenPos.x, 2) + Math.pow(y - screenPos.y, 2)
            );
            
            if (distance < 15) {
                this.selectedCamera = camera;
                this.onCameraSelect(camera);
            }
        });
        
        this.render();
    }

    handleMouseMove(e) {
        const rect = this.canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        
        let hovering = false;
        
        this.cameras.forEach(camera => {
            const screenPos = this.project3DTo2D(camera.position);
            const distance = Math.sqrt(
                Math.pow(x - screenPos.x, 2) + Math.pow(y - screenPos.y, 2)
            );
            
            if (distance < 15) {
                hovering = true;
            }
        });
        
        this.canvas.style.cursor = hovering ? 'pointer' : 'default';
    }

    project3DTo2D(position) {
        // Simple isometric projection
        const scale = 2;
        const offsetX = this.canvas.width / 2;
        const offsetY = this.canvas.height / 2;
        
        return {
            x: offsetX + (position.x - position.y) * scale,
            y: offsetY + (position.x + position.y) * scale / 2 - position.z * scale
        };
    }

    render() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Draw grid
        this.drawGrid();
        
        // Draw services
        this.services.forEach(service => this.drawService(service));
        
        // Draw cameras
        this.cameras.forEach(camera => this.drawCamera(camera));
    }

    drawGrid() {
        this.ctx.strokeStyle = 'rgba(148, 163, 184, 0.2)';
        this.ctx.lineWidth = 1;
        
        for (let i = -5; i <= 5; i++) {
            const start = this.project3DTo2D({ x: i * 50, y: -250, z: 0 });
            const end = this.project3DTo2D({ x: i * 50, y: 250, z: 0 });
            
            this.ctx.beginPath();
            this.ctx.moveTo(start.x, start.y);
            this.ctx.lineTo(end.x, end.y);
            this.ctx.stroke();
            
            const start2 = this.project3DTo2D({ x: -250, y: i * 50, z: 0 });
            const end2 = this.project3DTo2D({ x: 250, y: i * 50, z: 0 });
            
            this.ctx.beginPath();
            this.ctx.moveTo(start2.x, start2.y);
            this.ctx.lineTo(end2.x, end2.y);
            this.ctx.stroke();
        }
    }

    drawService(service) {
        // Service areas represented as rectangles
        // This is a simplified version
    }

    drawCamera(camera) {
        const pos = this.project3DTo2D(camera.position);
        const isSelected = this.selectedCamera && this.selectedCamera.id === camera.id;
        const isOnline = camera.isActive && this.isCameraOnline(camera);
        
        // Draw camera icon
        this.ctx.fillStyle = isOnline ? '#10b981' : '#ef4444';
        this.ctx.strokeStyle = isSelected ? '#6366f1' : 'rgba(148, 163, 184, 0.5)';
        this.ctx.lineWidth = isSelected ? 3 : 1;
        
        this.ctx.beginPath();
        this.ctx.arc(pos.x, pos.y, 10, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.stroke();
        
        // Draw label
        this.ctx.fillStyle = '#f1f5f9';
        this.ctx.font = '12px Inter';
        this.ctx.textAlign = 'center';
        this.ctx.fillText(camera.name, pos.x, pos.y - 15);
    }

    isCameraOnline(camera) {
        if (!camera.lastActive) return false;
        const now = new Date();
        const lastActive = new Date(camera.lastActive);
        const diffMinutes = (now - lastActive) / 1000 / 60;
        return diffMinutes < 2; // Online if active in last 2 minutes
    }

    onCameraSelect(camera) {
        // Override this method to handle camera selection
        console.log('Camera selected:', camera);
    }
}

// Initialize app
let app, cameraManager, queueManager, campusMap;

document.addEventListener('DOMContentLoaded', () => {
    app = new AdminApp();
    cameraManager = new CameraStreamManager();
    queueManager = new QueueManager();
    
    // Initialize 3D map if canvas exists
    const mapCanvas = document.getElementById('campus-map-3d');
    if (mapCanvas) {
        campusMap = new CampusMap3D('campus-map-3d');
    }
});
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

    // Show stats (readonly)
    document.getElementById('edit_service_pending').value = card.dataset.pending || 0;
    document.getElementById('edit_service_active').value = card.dataset.active || 0;
    document.getElementById('edit_service_served').value = card.dataset.served || 0;

    app.openModal('modalEditService');
}


// Add CSS animations
const style = document.createElement('style');
style.textContent = `
    @keyframes slideInRight {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOutRight {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }
    
    .queue-entry {
        padding: 1rem;
        background: rgba(255, 255, 255, 0.05);
        border-radius: 0.5rem;
        margin-bottom: 0.5rem;
        transition: all 0.3s ease;
    }
    
    .queue-entry:hover {
        background: rgba(255, 255, 255, 0.1);
        transform: translateX(4px);
    }
`;
document.head.appendChild(style);
