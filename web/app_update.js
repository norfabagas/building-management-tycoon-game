// Packaged with one UTC timestamp shared by Dart, the worker and app-version.json.
function createTycoonUpdates(env, buildVersion) {
  const base = env.document.baseURI;
  const workers = env.navigator.serviceWorker;
  const registration = workers
    ? workers.register(new URL('offline_worker.js', base), {updateViaCache: 'none'}).catch(() => null)
    : Promise.resolve(null);
  const delay = ms => new Promise(resolve => env.setTimeout(resolve, ms));
  let pendingSync;

  function bounded(promise, milliseconds) {
    let timer;
    const timeout = new Promise((_, reject) => {
      timer = env.setTimeout(() => reject(new Error('Update request timed out')), milliseconds);
    });
    return Promise.race([promise, timeout]).finally(() => env.clearTimeout(timer));
  }

  async function check() {
    const url = new URL('app-version.json', base);
    url.searchParams.set('check', String(env.Date.now()));
    return bounded((async () => {
      const response = await env.fetch(url, {cache: 'no-store', credentials: 'same-origin'});
      if (!response.ok) throw new Error('Version unavailable');
      const metadata = await response.json();
      if (!/^\d{17}$/.test(metadata.version)) throw new Error('Invalid release version');
      return metadata.version;
    })(), 12000);
  }

  function message(worker, data) {
    return new Promise((resolve, reject) => {
      const channel = new env.MessageChannel();
      const timer = env.setTimeout(() => { channel.port1.close(); reject(new Error('Worker did not respond')); }, 10000);
      channel.port1.onmessage = event => {
        env.clearTimeout(timer);
        channel.port1.close();
        resolve(event.data);
      };
      worker.postMessage(data, [channel.port2]);
    });
  }

  async function performSync(version) {
    if (await check() !== version) return 'changed';
    const reg = await bounded(registration, 30000);
    if (!reg) throw new Error('Offline updates unavailable');
    await bounded(reg.update(), 30000);
    const deadline = env.Date.now() + 120000;
    let target;
    while (env.Date.now() < deadline) {
      const candidate = reg.waiting || (!reg.installing ? reg.active : null);
      if (candidate) {
        const info = await message(candidate, {type: 'VERSION'});
        if (info.version === version) { target = candidate; break; }
      }
      if (!reg.installing && !reg.waiting) throw new Error('Update not installed');
      await delay(150);
    }
    if (!target) throw new Error('Update installation timed out');
    if (await check() !== version) return 'changed';
    // The worker rechecks the client list at activation, preventing a reload of
    // another tab's live game or mixed-version requests from that session.
    const reply = await message(target, {type: 'ACTIVATE', version});
    if (reply.result !== 'ok') return reply.result || 'failed';
    const activationDeadline = env.Date.now() + 20000;
    while (env.Date.now() < activationDeadline) {
      if (workers.controller) {
        const info = await message(workers.controller, {type: 'VERSION'});
        if (info.version === version) {
          env.location.reload();
          return 'reloading';
        }
      }
      await delay(100);
    }
    throw new Error('Update activation timed out');
  }

  return {
    version: buildVersion,
    check,
    sync(version) {
      if (!pendingSync) pendingSync = performSync(version).finally(() => { pendingSync = null; });
      return pendingSync;
    },
  };
}

if (typeof window !== 'undefined') window.tycoonUpdates = createTycoonUpdates(window, '__BUILD_VERSION__');
