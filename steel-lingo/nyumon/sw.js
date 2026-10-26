/* 스틸링고 입문 — 서비스워커
   같은 주소에 스틸링고 Lite·Pro·出張編이 함께 산다. 지울 때는 "nyumon-"으로 시작하는 내 캐시만 지운다.
   다른 앱이 캐시를 지울 수도 있어서, 앱이 열릴 때마다 비었는지 확인해 다시 채운다(ensure-cache).
   - 화면 파일(HTML·JS·CSS): 네트워크 먼저, 2.5초 안에 안 오면 저장본 → 인터넷 없이도 열린다
   - 음성·그림·아이콘: 바뀌지 않으므로 저장본 먼저
   새 버전을 올릴 때는 VERSION 숫자를 올린다. */
importScripts("audio/manifest.js");
const PREFIX = "nyumon-";
const VERSION = 2;
const CACHE = PREFIX + "v" + VERSION;
const TIMEOUT = 2500;
const SHELL = [
  "./", "./index.html", "./manifest.webmanifest", "./css/app.css", "./js/data.js", "./js/app.js", "./audio/manifest.js",
  "./icons/icon-192.png", "./icons/icon-512.png", "./icons/icon-maskable-512.png", "./icons/apple-touch-icon.png",
  "./char/dogeum_curious.webp","./char/dogeum_grin.webp","./char/dogeum_happy.webp","./char/dogeum_relaxed.webp","./char/eg_calm.webp","./char/eg_off.webp","./char/eg_polite.webp","./char/eg_work.webp","./char/poo_basic.webp","./char/poo_relief.webp","./char/poo_surprise.webp","./char/poo_tired.webp","./char/ssial_basic.webp","./char/ssial_fire.webp","./char/ssial_happy.webp","./char/ssial_shock.webp","./char/tarae_happy.webp","./char/tarae_puzzled.webp","./char/tarae_serious.webp","./char/tarae_surprised.webp"
].concat(Object.values((self.NY && self.NY.AUDIO) || {}).map((f) => "./audio/" + f));

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
    fetch(req).then((res) => {
      if (!res || !res.ok) throw 0;
      const copy = res.clone(); caches.open(CACHE).then((c) => c.put(req, copy));
      clearTimeout(t); finish(res);
    }).catch(() => { clearTimeout(t); fromCache().then((r) => finish(r || Response.error())); });
  });
}
self.addEventListener("fetch", (e) => {
  const req = e.request, url = new URL(req.url);
  if (req.method !== "GET" || url.origin !== location.origin || !url.pathname.includes("/nyumon/")) return;
  if (/\/(audio|char|icons)\/.+\.(mp3|webp|png)$/.test(url.pathname)) {
    e.respondWith(caches.open(CACHE).then((c) => c.match(req).then((hit) => hit || fetch(req).then((r) => { if (r.ok) c.put(req, r.clone()); return r; }))));
    return;
  }
  e.respondWith(networkFirst(req.mode === "navigate" ? new Request("./index.html", { cache: "no-store" }) : req));
});
