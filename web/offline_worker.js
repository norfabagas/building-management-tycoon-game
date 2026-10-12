// Build with tool/build_web.dart to replace the version and generate the manifest.
const CACHE_NAME = 'tycoon-app-__BUILD_VERSION__';
const CACHE_PREFIX = 'tycoon-app-';

self.addEventListener('install', event => {
  event.waitUntil((async () => {
    const base = self.registration.scope;
    const response = await fetch(new URL('offline-assets.json', base), {cache: 'no-store'});
    if (!response.ok) throw new Error('Offline asset manifest unavailable');
    const files = await response.json();
    const cache = await caches.open(CACHE_NAME);
    await cache.addAll(files.map(file => new URL(file, base).href));
  })());
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names.filter(name => name.startsWith(CACHE_PREFIX) && name !== CACHE_NAME).map(name => caches.delete(name)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== self.location.origin) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE_NAME);
    const cached = await cache.match(request, {ignoreSearch: true});
    if (cached) return cached;
    if (request.mode === 'navigate') {
      const index = await cache.match(new URL('index.html', self.registration.scope).href);
      if (index) return index;
    }
    return fetch(request);
  })());
});
