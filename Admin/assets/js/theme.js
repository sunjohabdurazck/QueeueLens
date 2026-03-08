(function () {
  const STORAGE_KEY = 'ql-theme-preference';
  const root = document.documentElement;
  const media = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;

  function getStoredPreference() {
    try { return localStorage.getItem(STORAGE_KEY) || 'system'; }
    catch (e) { return 'system'; }
  }

  function effectiveTheme(pref) {
    if (pref === 'light' || pref === 'dark') return pref;
    return media && media.matches ? 'dark' : 'light';
  }

  function applyTheme(pref, persist) {
    const preference = pref || getStoredPreference();
    const theme = effectiveTheme(preference);
    root.setAttribute('data-theme', theme);
    root.setAttribute('data-theme-preference', preference);
    root.style.colorScheme = theme;
    document.querySelectorAll('[data-theme-option]').forEach(btn => {
      btn.classList.toggle('active', btn.getAttribute('data-theme-option') === preference);
      btn.setAttribute('aria-pressed', btn.classList.contains('active') ? 'true' : 'false');
    });
    const label = document.querySelector('[data-theme-current-label]');
    if (label) label.textContent = preference.charAt(0).toUpperCase() + preference.slice(1);
    if (persist) {
      try { localStorage.setItem(STORAGE_KEY, preference); } catch (e) {}
    }
  }

  window.QueueLensTheme = {
    apply: function (pref) { applyTheme(pref, true); },
    refresh: function () { applyTheme(getStoredPreference(), false); },
    currentPreference: getStoredPreference,
    effectiveTheme: function () { return effectiveTheme(getStoredPreference()); }
  };

  document.addEventListener('DOMContentLoaded', function () {
    applyTheme(getStoredPreference(), false);
    document.querySelectorAll('[data-theme-option]').forEach(btn => {
      btn.addEventListener('click', function () {
        applyTheme(btn.getAttribute('data-theme-option'), true);
      });
    });
  });

  if (media && typeof media.addEventListener === 'function') {
    media.addEventListener('change', function () {
      if (getStoredPreference() === 'system') applyTheme('system', false);
    });
  } else if (media && typeof media.addListener === 'function') {
    media.addListener(function () {
      if (getStoredPreference() === 'system') applyTheme('system', false);
    });
  }

  applyTheme(getStoredPreference(), false);
})();
