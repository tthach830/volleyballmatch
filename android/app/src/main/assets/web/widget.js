/**
 * Set Games - Volleyball? Beach Weather Widget Embed Loader
 * https://github.com/tthach830/volleyballmatch
 * 
 * Usage:
 * <div id="volleyball-weather-widget" data-beach="Main Beach" data-theme="dark"></div>
 * <script src="widget.js" async></script>
 */
(function() {
  function getScriptBaseUrl() {
    try {
      const scripts = document.getElementsByTagName('script');
      for (let i = scripts.length - 1; i >= 0; i--) {
        const src = scripts[i].src;
        if (src && src.includes('widget.js')) {
          return src.substring(0, src.lastIndexOf('/') + 1);
        }
      }
    } catch (e) {}
    return window.location.origin + '/';
  }

  const baseUrl = getScriptBaseUrl();

  function initWidget() {
    // Find target containers
    const containers = document.querySelectorAll('#volleyball-weather-widget, [data-volleyball-widget]');
    if (!containers || containers.length === 0) return;

    containers.forEach((container, idx) => {
      if (container.dataset.initialized) return;
      container.dataset.initialized = 'true';

      const beach = container.getAttribute('data-beach') || 'Main Beach';
      const theme = container.getAttribute('data-theme') || 'dark';
      const view = container.getAttribute('data-view') || 'full';
      const minTemp = container.getAttribute('data-min-temp') || '60';
      const maxTemp = container.getAttribute('data-max-temp') || '80';
      const maxWind = container.getAttribute('data-max-wind') || '10';
      const maxUv = container.getAttribute('data-max-uv') || '4.0';

      const params = new URLSearchParams({
        beach,
        theme,
        view,
        minTemp,
        maxTemp,
        maxWind,
        maxUv
      });

      const iframe = document.createElement('iframe');
      iframe.src = `${baseUrl}widget.html?${params.toString()}`;
      iframe.title = 'Volleyball? Beach Weather Forecast';
      iframe.style.width = '100%';
      iframe.style.height = view === 'compact' ? '320px' : '480px';
      iframe.style.border = 'none';
      iframe.style.borderRadius = '16px';
      iframe.style.overflow = 'hidden';
      iframe.style.boxShadow = '0 8px 30px rgba(0,0,0,0.15)';
      iframe.loading = 'lazy';
      iframe.setAttribute('scrolling', 'no');

      container.innerHTML = '';
      container.appendChild(iframe);

      // Listen for resize messages
      window.addEventListener('message', function(event) {
        if (event.data && event.data.type === 'setgames-widget-resize' && event.data.height) {
          iframe.style.height = (event.data.height + 8) + 'px';
        }
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initWidget);
  } else {
    initWidget();
  }
})();
