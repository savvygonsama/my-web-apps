/* BUILD-UP — 서비스워커
   같은 주소(my-web-apps)에 다른 앱들이 함께 산다. 지울 때는 "buildup-"으로 시작하는 내 캐시만 지운다.
   - 화면·원고(HTML·JS): 네트워크 먼저, 2.5초 안에 안 오면 저장본 → 인터넷 없이도 열린다. 새 회차도 바로 들어온다
   - 아이콘·매니페스트: 바뀌지 않으므로 저장본 먼저
   새 버전을 올릴 때는 VERSION 숫자를 올린다. */
const PREFIX = "buildup-";
const VERSION = 1;
const CACHE = PREFIX + "v" + VERSION;
const TIMEOUT = 2500;
const SHELL = [
  "./", "./index.html", "./manifest.json",
  "./js/data.js", "./js/days-w1.js", "./js/days-w2.js", "./js/days-w3.js", "./js/days-w4.js", "./js/app.js",
  "./icon-192.png", "./icon-512.png", "./icon-maskable-512.png", "./apple-touch-icon.png"
];
async function fill(onlyMissing) {
  const c = await caches.open(CACHE);
  await Promise.all(SHELL.map(async (u) => {
    if (onlyMissing && (await c.match(u))) return;
    try { const r = await fetch(new Request(u, { cache: "reload" })); if (r.ok) await c.put(u, r); } catch (e) {}
  }));
}
self.addEventListener("install", (e) => e.waitUntil(fill(false).then(() => self.skipWaiting())));
self.addEventListener("activate", (e) => e.waitUntil(
  caches.keys().then((ks) => Promise.all(ks.filter((k) => k.startsWith(PREFIX) && k !== CACHE).map((k) => caches.delete(k))))
    .then(() => self.clients.claim())));
self.addEventListener("message", (e) => { if (e.data && e.data.type === "ensure-cache") e.waitUntil(fill(true)); });

function networkFirst(req) {
  return new Promise((resolve) => {
    let done = false;
    const finish = (r) => { if (!done && r) { done = true; resolve(r); } };
    const fromCache = () => caches.open(CACHE).then((c) => c.match(req, { ignoreSearch: true }));
    const t = setTimeout(() => fromCache().then(finish), TIMEOUT);
    fetch(new Request(req, { cache: "no-cache" })).then((res) => {
      if (!res || !res.ok) throw 0;
      const copy = res.clone(); caches.open(CACHE).then((c) => c.put(req, copy));
      clearTimeout(t); finish(res);
    }).catch(() => { clearTimeout(t); fromCache().then((r) => finish(r || Response.error())); });
  });
}
self.addEventListener("fetch", (e) => {
  const req = e.request, url = new URL(req.url);
  if (req.method !== "GET" || url.origin !== location.origin || !url.pathname.includes("/buildup/")) return;
  if (/\.(png|json)$/.test(url.pathname)) {
    e.respondWith(caches.open(CACHE).then((c) => c.match(req).then((hit) => hit || fetch(req).then((r) => { if (r.ok) c.put(req, r.clone()); return r; }))));
    return;
  }
  e.respondWith(networkFirst(req.mode === "navigate" ? new Request("./index.html") : req));
});
