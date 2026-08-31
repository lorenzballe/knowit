// Serve the rendering engine from the deploy rather than from the gstatic
// CDN. It is about five megabytes: fetched from the same origin it arrives
// with everything else and is cached with the build, instead of being a
// separate cross-origin round trip on every cold load — and it still works on
// a network that blocks Google's CDN.

// Evict any service worker left behind by an older build. Newer builds do not
// register one, but not registering does not remove the one already there:
// it keeps control of the page and keeps serving the build it cached, so a
// deploy lands and nobody sees it. Unregistering does not affect the load
// already in progress, so when one was in charge the page is reloaded once —
// guarded, because a reload loop is worse than a stale page.
(function evictOldServiceWorker() {
  if (!('serviceWorker' in navigator)) return;
  var wasControlled = !!navigator.serviceWorker.controller;
  navigator.serviceWorker.getRegistrations().then(function (registrations) {
    var work = registrations.map(function (r) { return r.unregister(); });
    if (window.caches) {
      work.push(caches.keys().then(function (keys) {
        return Promise.all(keys.map(function (k) { return caches.delete(k); }));
      }));
    }
    return Promise.all(work);
  }).then(function () {
    if (!wasControlled) return;
    try {
      if (sessionStorage.getItem('sw-evicted')) return;
      sessionStorage.setItem('sw-evicted', '1');
    } catch (e) {
      return; // No sessionStorage means no way to guard the loop: leave it.
    }
    location.reload();
  }).catch(function () {});
})();

{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
