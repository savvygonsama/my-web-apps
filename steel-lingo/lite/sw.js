/* 스틸링고 Lite — 서비스워커
   내용(회차)이 계속 늘어나는 앱이라, 본문 HTML은 항상 새것을 먼저 받는다.
   네트워크가 없을 때만 캐시로 떨어진다. 아이콘 같은 정적 파일은 캐시를 먼저 쓴다. */
const CACHE = 'steel-lingo-lite-v4';
const SHELL = ['./index.html', './manifest.json', './icon-192.png', './icon-512.png'];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE)
      // HTTP 캐시를 건너뛰고 받아야 갱신된 회차가 들어온다
      .then((c) => Promise.all(
        SHELL.map((u) => fetch(new Request(u, { cache: 'reload' }))
          .then((res) => (res.ok ? c.put(u, res) : null))
          .catch(() => null))
      ))
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

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;

  const isDoc = req.mode === 'navigate' || req.destination === 'document';

  if (isDoc) {
    // 새 회차를 놓치지 않도록 네트워크 우선
    e.respondWith(
      fetch(req)
        .then((res) => {
          if (res.ok) {
            const copy = res.clone();
            caches.open(CACHE).then((c) => c.put('./index.html', copy));
          }
          return res;
        })
        .catch(() => caches.match('./index.html').then((r) => r || caches.match(req)))
    );
    return;
  }

  e.respondWith(
    caches.match(req).then((cached) => cached || fetch(req).then((res) => {
      if (res.ok) {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(req, copy));
      }
      return res;
    }))
  );
});
