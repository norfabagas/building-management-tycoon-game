// Build with tool/build_web.dart to replace the version and generate the manifest.
const CACHE_NAME = 'tycoon-app-__BUILD_VERSION__';
const CACHE_PREFIX = 'tycoon-app-';
const BUILD_VERSION = '__BUILD_VERSION__';

async function releaseVersion() {
  const response = await fetch(new URL('app-version.json', self.registration.scope), {cache: 'no-store'});
  if (!response.ok || (await response.json()).version !== BUILD_VERSION) {
    throw new Error('Release changed during installation');
  }
}

self.addEventListener('install', event => {
  event.waitUntil((async () => {
    const base = self.registration.scope;
    await releaseVersion();
    const response = await fetch(new URL('offline-assets.json', base), {cache: 'no-store'});
    if (!response.ok) throw new Error('Offline asset manifest unavailable');
    const files = await response.json();
    const cache = await caches.open(CACHE_NAME);
    await cache.addAll(files.map(file => new Request(new URL(file, base), {cache: 'reload'})));
    await releaseVersion();
  })());
});

self.addEventListener('message', event => {
  if (!event.ports?.[0] || !event.source?.url?.startsWith(self.registration.scope)) return;
  const reply = value => event.ports[0].postMessage(value);
  if (event.data?.type === 'VERSION') { reply({version: BUILD_VERSION}); return; }
  if (event.data?.type !== 'ACTIVATE' || event.data.version !== BUILD_VERSION) return;
  event.waitUntil((async () => {
    const clients = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
    if (clients.some(client => client.id !== event.source.id && client.url.startsWith(self.registration.scope))) {
      reply({result: 'other-tabs'});
      return;
    }
    reply({result: 'ok'});
    await self.skipWaiting();
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
  // Release metadata must never fall back to the cached shell or an old pack.
  if (url.pathname === new URL('app-version.json', self.registration.scope).pathname) {
    event.respondWith(fetch(request, {cache: 'no-store'}));
    return;
  }
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
