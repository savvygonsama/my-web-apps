/* 스틸링고 大阪物語 — 서비스워커 (엔진은 出張編·大阪編과 같다)

   같은 주소(savvygonsama.github.io)에 스틸링고 Lite·Pro 등 다른 앱이 함께 산다.
   캐시 저장소는 주소 단위로 공유되므로, 지울 때는 내 접두사(SH_APP.cachePrefix)로 시작하는 것만 지운다.
   다른 앱이 내 캐시를 지워 버릴 수도 있어서, 앱이 열릴 때마다 비었는지 확인해 다시 채운다(ensure-cache).

   전략
   - 글꼴·아이콘: 바뀌지 않으므로 캐시 먼저
   - 나머지(HTML·JS·CSS·데이터): 네트워크 먼저, 2.5초 안에 안 오면 저장본 → 인터넷이 없어도 열린다 */
importScripts("data/index.js");

const PREFIX = (self.SH_APP && self.SH_APP.cachePrefix) || "osakamono-";
const CACHE = PREFIX + "v2";
const TIMEOUT = 2500;
const SHELL = [
  "./", "./index.html", "./manifest.webmanifest",
  "./css/app.css", "./css/theme.css", "./js/core.js", "./js/app.js", "./data/index.js",
  "./icons/icon.svg", "./icons/icon-192.png", "./icons/icon-512.png", "./icons/icon-maskable-512.png", "./icons/apple-touch-icon.png",
  "./fonts/notojp-400.woff2", "./fonts/notojp-700.woff2", "./fonts/pretendard-400.woff2", "./fonts/pretendard-700.woff2"
].concat((self.SH_DATA_FILES || []).map((f) => "./data/" + f));

async function fill(onlyMissing) {
  const c = await caches.open(CACHE);
  await Promise.all(SHELL.map(async (u) => {
    if (onlyMissing && (await c.match(u))) return;
    try {
      const res = await fetch(new Request(u, { cache: "reload" }));
      if (res.ok) await c.put(u, res);
    } catch (e) { /* 오프라인이면 다음 기회에 */ }
  }));
}

self.addEventListener("install", (e) => {
  e.waitUntil(fill(false).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k.startsWith(PREFIX) && k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("message", (e) => {
  if (e.data && e.data.type === "ensure-cache") e.waitUntil(fill(true));
});

function networkFirst(req, key) {
  return new Promise((resolve) => {
    let done = false;
    const finish = (r) => { if (!done && r) { done = true; resolve(r); } };
    const fromCache = () => caches.open(CACHE).then((c) => c.match(key || req, { ignoreSearch: true }));
    const timer = setTimeout(() => fromCache().then(finish), TIMEOUT);
    fetch(req)
      .then((res) => {
        if (!res || !res.ok) throw new Error("bad");
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(key || req, copy));
        clearTimeout(timer);
        finish(res);
      })
      .catch(async () => {
        clearTimeout(timer);
        const r = await fromCache();
        finish(r || Response.error());
      });
  });
}

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  if (url.origin !== location.origin) return;

  if (req.mode === "navigate") {
    e.respondWith(networkFirst(req, "./index.html"));
    return;
  }
  if (/\/(fonts|icons)\//.test(url.pathname)) {
    e.respondWith(
      caches.open(CACHE).then((c) => c.match(req).then((hit) => hit || fetch(req).then((res) => {
        if (res.ok) c.put(req, res.clone());
        return res;
      })))
    );
    return;
  }
  e.respondWith(networkFirst(req));
});
