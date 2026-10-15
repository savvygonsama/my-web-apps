/* 이번 주 식탁 — 서비스워커 (홈 화면 설치 + 오프라인)

   화면(HTML)은 열 때마다 서버에 새것이 있는지 먼저 물어본다. 그래서 GitHub에 고친 것을
   올리면 다음에 열 때 바로 반영된다. 3초 안에 답이 없거나 인터넷이 끊겨 있으면
   저장해 둔 것으로 연다.
   아이콘·글꼴처럼 바뀌지 않는 것은 저장본을 먼저 쓴다. */
const CACHE = 'meal-planner-v1';
const SHELL = ["./index.html", "./manifest.json", "./icons/icon-192.png", "./icons/icon-512.png", "./icons/apple-touch-icon.png"];
const DOC_TIMEOUT = 3000;

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE)
      .then((c) => Promise.all(SHELL.map((u) =>
        fetch(new Request(u, { cache: 'reload' }))
          .then((res) => (res.ok ? c.put(u, res) : null))
          .catch(() => null))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

/* 주소 끝의 ?·# 를 떼고, 폴더 주소(…/)는 index.html 로 맞춰 저장한다 */
function docKey(url) {
  const u = new URL(url);
  u.search = ''; u.hash = '';
  if (u.pathname.endsWith('/')) u.pathname += 'index.html';
  return u.href;
}

function docStrategy(req) {
  const key = docKey(req.url);
  return new Promise((resolve) => {
    let done = false;
    const finish = (r) => { if (!done && r) { done = true; resolve(r); } };
    const timer = setTimeout(() => { caches.match(key).then(finish); }, DOC_TIMEOUT);
    fetch(new Request(key, { cache: 'no-cache' }))
      .then((res) => {
        if (!res || !res.ok) throw new Error('bad');
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(key, copy));
        clearTimeout(timer);
        finish(res);
      })
      .catch(async () => {
        clearTimeout(timer);
        const cached = await caches.match(key);
        finish(cached || Response.error());
      });
  });
}

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  if (req.mode === 'navigate' || req.destination === 'document') {
    if (url.origin === location.origin) e.respondWith(docStrategy(req));
    return;
  }

  const sameOrigin = url.origin === location.origin;
  const fonts = /(^|\.)fonts\.(googleapis|gstatic)\.com$/.test(url.hostname);
  if (!sameOrigin && !fonts) return;

  e.respondWith(
    caches.match(req).then((cached) => cached || fetch(req).then((res) => {
      if (res && (res.ok || res.type === 'opaque')) {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(req, copy));
      }
      return res;
    }))
  );
});
