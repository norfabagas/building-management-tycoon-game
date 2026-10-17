import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../web/offline_worker.js', import.meta.url), 'utf8')
  .replaceAll('__BUILD_VERSION__', 'test');
const scope = 'https://district.test/game/';
const manifest = ['index.html', 'main.dart.js', 'assets/room.png'];

function harness() {
  const handlers = new Map();
  const packs = new Map();
  const requests = [];
  let online = true, missing, claims = 0;
  const urlOf = value => new URL(typeof value === 'string' ? value : value.url ?? value.href, scope);
  const fetch = async value => {
    const url = urlOf(value).href;
    requests.push(url);
    if (!online) throw new Error('Network unavailable');
    if (url === missing) return new Response('Not found', { status: 404 });
    return new Response(url.endsWith('offline-assets.json') ? JSON.stringify(manifest) : url);
  };
  const caches = {
    async open(name) {
      if (!packs.has(name)) {
        const files = new Map();
        packs.set(name, {
          async addAll(urls) {
            const entries = await Promise.all(urls.map(async url => {
              const response = await fetch(url);
              if (!response.ok) throw new Error('Required asset unavailable');
              return [urlOf(url).href, response];
            }));
            for (const [url, response] of entries) files.set(url, response);
          },
          async match(value, { ignoreSearch = false } = {}) {
            const url = urlOf(value);
            if (ignoreSearch) url.search = '';
            return files.get(url.href)?.clone();
          },
        });
      }
      return packs.get(name);
    },
    async keys() { return [...packs.keys()]; },
    async delete(name) { return packs.delete(name); },
  };
  vm.runInNewContext(source, { URL, caches, fetch, self: {
    registration: { scope }, location: { origin: new URL(scope).origin },
    clients: { async claim() { claims++; } },
    addEventListener(name, handler) { handlers.set(name, handler); },
  }});
  const dispatch = (name, extra = {}) => {
    let pending;
    handlers.get(name)({ ...extra, waitUntil(value) { pending = value; }, respondWith(value) { pending = value; } });
    return pending;
  };
  return {
    caches, packs, requests, dispatch,
    setOnline(value) { online = value; }, setMissing(value) { missing = value; },
    get claims() { return claims; },
    request(path, mode = 'cors', method = 'GET') {
      return dispatch('fetch', { request: { url: new URL(path, scope).href, method, mode } });
    },
  };
}

test('first installation caches every declared resource under the deployment scope', async () => {
  const app = harness();
  await app.dispatch('install');
  const pack = await app.caches.open('tycoon-app-test');
  for (const file of manifest) assert.equal(await (await pack.match(scope + file)).text(), scope + file);
  assert.deepEqual(app.requests, [scope + 'offline-assets.json', ...manifest.map(file => scope + file)]);
});

test('cached startup and art survive network failure and cache-busting query parameters', async () => {
  const app = harness();
  await app.dispatch('install');
  app.requests.length = 0;
  app.setOnline(false);
  for (const file of manifest) assert.equal(await (await app.request(file + '?v=reload')).text(), scope + file);
  assert.equal(app.requests.length, 0);
});

test('an offline navigation reload uses the cached app shell', async () => {
  const app = harness();
  await app.dispatch('install');
  app.setOnline(false);
  assert.equal(await (await app.request('district/floor/2', 'navigate')).text(), scope + 'index.html');
});

test('activation removes old app packs while retaining unrelated caches', async () => {
  const app = harness();
  await app.caches.open('tycoon-app-old');
  await app.caches.open('unrelated-data');
  await app.dispatch('install');
  await app.dispatch('activate');
  assert.deepEqual((await app.caches.keys()).sort(), ['tycoon-app-test', 'unrelated-data']);
  assert.equal(app.claims, 1);
});

test('failed precaching rejects installation without deleting the active offline pack', async () => {
  const app = harness();
  await app.caches.open('tycoon-app-old');
  app.setMissing(scope + 'assets/room.png');
  await assert.rejects(app.dispatch('install'), /Required asset unavailable/);
  assert.ok(app.packs.has('tycoon-app-old'));
  assert.equal(app.claims, 0);
});

test('foreign requests and writes pass through; missing offline media never becomes HTML', async () => {
  const app = harness();
  await app.dispatch('install');
  assert.equal(app.request('https://elsewhere.test/image.png'), undefined);
  assert.equal(app.request('save', 'cors', 'POST'), undefined);
  app.setOnline(false);
  await assert.rejects(app.request('missing.png'), /Network unavailable/);
});
