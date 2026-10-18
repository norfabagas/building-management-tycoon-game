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
  let online = true, missing, claims = 0, skips = 0;
  let clients = [{id: 'current', url: scope}];
  let releaseReads = 0, changeOnRead = Infinity;
  const urlOf = value => new URL(typeof value === 'string' ? value : value.url ?? value.href, scope);
  const fetch = async value => {
    const url = urlOf(value).href;
    requests.push(url);
    if (!online) throw new Error('Network unavailable');
    if (url === missing) return new Response('Not found', { status: 404 });
    return new Response(url.endsWith('offline-assets.json') ? JSON.stringify(manifest) : new URL(url).pathname.endsWith('app-version.json') ? JSON.stringify({version: ++releaseReads >= changeOnRead ? 'changed' : 'test'}) : url);
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
  vm.runInNewContext(source, { URL, Request, caches, fetch, self: {
    registration: { scope }, location: { origin: new URL(scope).origin },
    clients: { async claim() { claims++; }, async matchAll() { return clients; } },
    async skipWaiting() { skips++; },
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
    setClients(value) { clients = value; },
    changeReleaseOnRead(value) { changeOnRead = value; },
    get claims() { return claims; },
    get skips() { return skips; },
    async message(type, version = 'test', source = {id: 'current', url: scope}) {
      let reply;
      await dispatch('message', {data: {type, version}, source, ports: [{postMessage(value) {reply = value;}}]});
      return reply;
    },
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
  assert.deepEqual(app.requests, [scope + 'app-version.json', scope + 'offline-assets.json', ...manifest.map(file => scope + file), scope + 'app-version.json']);
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

test('release metadata bypasses even a stale cached response and fails honestly offline', async () => {
  const app = harness();
  await app.dispatch('install');
  app.requests.length = 0;
  assert.equal((await (await app.request('app-version.json?check=1')).json()).version, 'test');
  assert.equal(app.requests.length, 1);
  app.setOnline(false);
  await assert.rejects(app.request('app-version.json'), /Network unavailable/);
});

test('explicit activation identifies its version and refuses other open game tabs', async () => {
  const app = harness();
  assert.equal((await app.message('VERSION')).version, 'test');
  app.setClients([{id: 'current', url: scope}, {id: 'game', url: scope + 'floor'}]);
  assert.equal((await app.message('ACTIVATE')).result, 'other-tabs');
  assert.equal(app.skips, 0);
  app.setClients([{id: 'current', url: scope}, {id: 'other', url: 'https://district.test/unrelated/'}]);
  assert.equal((await app.message('ACTIVATE')).result, 'ok');
  assert.equal(app.skips, 1);
});

test('wrong-version and foreign-source activation are ignored', async () => {
  const app = harness();
  assert.equal(await app.message('ACTIVATE', 'wrong'), undefined);
  assert.equal(await app.message('ACTIVATE', 'test', {id: 'foreign', url: 'https://other.test/'}), undefined);
  assert.equal(app.skips, 0);
});

for (const boundary of [1, 2]) {
  test(`a deployment switch at installation boundary ${boundary} preserves the active pack`, async () => {
    const app = harness();
    await app.caches.open('tycoon-app-old');
    app.changeReleaseOnRead(boundary);
    await assert.rejects(app.dispatch('install'), /Release changed/);
    assert.ok(app.packs.has('tycoon-app-old'));
    assert.equal(app.claims, 0);
    assert.equal(app.skips, 0);
  });
}
