import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const create = vm.runInNewContext(readFileSync(new URL('../web/app_update.js', import.meta.url), 'utf8') + '\ncreateTycoonUpdates;', {URL, Promise});
const old = '20261018090000000', latest = '20261018100000000';

function harness() {
  let online = true, remote = latest, result = 'ok', reloads = 0, updates = 0;
  const requests = [], messages = [];
  const worker = {
    postMessage(data, ports) {
      messages.push(data);
      if (data.type === 'ACTIVATE' && result === 'ok') workers.controller = worker;
      queueMicrotask(() => ports[0].send(data.type === 'VERSION' ? {version: latest} : {result}));
    },
  };
  const registration = {waiting: worker, active: null, installing: null, async update() {updates++;}};
  const workers = {controller: null, async register(url, options) {
    assert.equal(url.href, 'https://game.test/sub/offline_worker.js');
    assert.equal(options.updateViaCache, 'none');
    return registration;
  }};
  const env = {
    document: {baseURI: 'https://game.test/sub/'}, navigator: {serviceWorker: workers},
    Date, setTimeout, clearTimeout,
    location: {reload() {reloads++;}},
    async fetch(url, options) {
      requests.push({url: url.href, options});
      if (!online) throw new Error('Offline');
      return {ok: true, async json() {return {version: remote};}};
    },
    MessageChannel: class {
      constructor() {
        this.port1 = {close() {}, onmessage: null};
        this.port2 = {send: data => this.port1.onmessage({data})};
      }
    },
  };
  return {
    api: create(env, old), env, requests, messages, registration,
    setOnline(value) {online = value;}, setVersion(value) {remote = value;}, setResult(value) {result = value;},
    get reloads() {return reloads;}, get updates() {return updates;},
  };
}

test('checks same-origin timestamp metadata with no-store and no cached fallback', async () => {
  const app = harness();
  assert.equal(app.api.version, old);
  assert.equal(await app.api.check(), latest);
  assert.match(app.requests[0].url, /^https:\/\/game.test\/sub\/app-version.json\?check=\d+$/);
  assert.equal(app.requests[0].options.cache, 'no-store');
  app.setOnline(false);
  await assert.rejects(app.api.check(), /Offline/);
});

test('invalid metadata never becomes an available release', async () => {
  const app = harness();
  app.setVersion('not-a-version');
  await assert.rejects(app.api.check(), /Invalid release/);
});

test('Sync activates the fully installed matching worker before reloading', async () => {
  const app = harness();
  assert.equal(await app.api.sync(latest), 'reloading');
  assert.equal(app.updates, 1);
  assert.equal(app.reloads, 1);
  assert.deepEqual(app.messages.map(x => x.type), ['VERSION', 'ACTIVATE', 'VERSION']);
});

test('a changed deployment requires a fresh review without activation or reload', async () => {
  const app = harness();
  app.setVersion('20261018110000000');
  assert.equal(await app.api.sync(latest), 'changed');
  assert.equal(app.reloads, 0);
  assert.equal(app.updates, 0);
});

test('other game tabs block activation; closing them allows a safe retry', async () => {
  const app = harness();
  app.setResult('other-tabs');
  assert.equal(await app.api.sync(latest), 'other-tabs');
  assert.equal(app.reloads, 0);
  app.setResult('ok');
  assert.equal(await app.api.sync(latest), 'reloading');
  assert.equal(app.reloads, 1);
});

test('offline Sync does not reload and retries without touching persistence', async () => {
  const app = harness();
  app.setOnline(false);
  await assert.rejects(app.api.sync(latest), /Offline/);
  assert.equal(app.reloads, 0);
  app.setOnline(true);
  assert.equal(await app.api.sync(latest), 'reloading');
});

test('duplicate Sync clicks share one update and one reload', async () => {
  const app = harness();
  const first = app.api.sync(latest), second = app.api.sync(latest);
  assert.equal(first, second);
  await Promise.all([first, second]);
  assert.equal(app.reloads, 1);
  assert.equal(app.updates, 1);
});

test('installation waits without messaging the legacy active worker', async () => {
  const app = harness();
  const next = app.registration.waiting;
  app.registration.waiting = null;
  app.registration.installing = {};
  app.registration.active = {postMessage() {throw new Error('Legacy worker has no update protocol');}};
  setTimeout(() => {app.registration.waiting = next; app.registration.installing = null;}, 20);
  assert.equal(await app.api.sync(latest), 'reloading');
  assert.equal(app.reloads, 1);
});

test('failed worker installation never activates or reloads the existing application', async () => {
  const app = harness();
  app.registration.update = async () => {throw new Error('Required resource unavailable');};
  await assert.rejects(app.api.sync(latest), /Required resource unavailable/);
  assert.equal(app.messages.length, 0);
  assert.equal(app.reloads, 0);
});
