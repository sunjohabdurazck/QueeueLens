</main>
</div>
<script>
// Global toast system
function showToast(msg, type='info') {
  const c = document.getElementById('toastContainer');
  if (!c) return;
  const t = document.createElement('div');
  t.className = `toast ${type}`;
  const icons = {success:'✅',error:'❌',info:'ℹ️',warning:'⚠️'};
  t.innerHTML = `<span>${icons[type]||'ℹ️'}</span><span>${msg}</span>`;
  c.appendChild(t);
  setTimeout(()=>{ t.style.opacity='0'; t.style.transition='opacity .4s'; setTimeout(()=>t.remove(),400); }, 3500);
}

// Modal system
document.querySelectorAll('[data-modal]').forEach(btn => {
  btn.addEventListener('click', () => {
    const id = btn.getAttribute('data-modal');
    const m = document.getElementById(id);
    if (m) m.classList.add('open');
  });
});
document.querySelectorAll('.modal-close, [data-close-modal]').forEach(el => {
  el.addEventListener('click', () => {
    el.closest('.modal-overlay')?.classList.remove('open');
  });
});
document.querySelectorAll('.modal-overlay').forEach(overlay => {
  overlay.addEventListener('click', e => {
    if (e.target === overlay) overlay.classList.remove('open');
  });
});

// Tab system
document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const group = btn.closest('[data-tabs]') || btn.closest('.tabs')?.parentElement;
    const target = btn.getAttribute('data-tab');
    group?.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    group?.querySelectorAll('.tab-panel').forEach(p => {
      p.classList.toggle('active', p.getAttribute('data-panel') === target);
    });
  });
});

// Queue action helper
async function queueAction(action, serviceId, entryId, reason) {
  const csrf = document.querySelector('meta[name="csrf-token"]')?.content
             || document.getElementById('csrf_token')?.value
             || window._csrfToken || '';
  const body = new URLSearchParams({action, serviceId, csrf_token: csrf});
  if (entryId) body.append('entryId', entryId);
  if (reason)  body.append('reason', reason);

  try {
    const r = await fetch(`${window._basePath||''}/api/queue-actions.php`, {method:'POST', body});
    const d = await r.json();
    showToast(d.message || (d.success ? 'Done' : 'Error'), d.success ? 'success' : 'error');
    if (d.success && typeof window.refreshPage === 'function') window.refreshPage();
    return d;
  } catch(e) {
    showToast('Network error', 'error');
    return {success:false};
  }
}

// Active sidebar link highlight
document.querySelectorAll('.sidebar-nav-link').forEach(link => {
  if (link.href === location.href) link.classList.add('active');
});

// Countdown timers
function updateCountdowns() {
  document.querySelectorAll('[data-expires]').forEach(el => {
    const exp = new Date(el.dataset.expires).getTime();
    const now = Date.now();
    const diff = Math.round((exp - now) / 1000);
    if (diff <= 0) {
      el.className = 'countdown urgent';
      el.textContent = 'EXPIRED';
    } else {
      const m = Math.floor(diff/60), s = diff%60;
      el.textContent = `${m}:${s.toString().padStart(2,'0')}`;
      el.className = 'countdown ' + (diff < 20 ? 'urgent' : diff < 60 ? 'warn' : 'ok');
    }
  });
}
updateCountdowns();
setInterval(updateCountdowns, 1000);

// Search filter for tables
document.querySelectorAll('[data-search]').forEach(input => {
  const target = document.querySelector(input.dataset.search);
  if (!target) return;
  input.addEventListener('input', () => {
    const q = input.value.toLowerCase();
    target.querySelectorAll('[data-searchable]').forEach(row => {
      row.style.display = row.textContent.toLowerCase().includes(q) ? '' : 'none';
    });
  });
});
</script>
</body>
</html>
