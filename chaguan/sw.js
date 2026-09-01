/* 茶馆 CHÁGUǍN — 서비스워커
   앱 전체가 HTML 파일 하나다. 캐시에 있으면 그것을 즉시 내주고,
   새 버전은 뒤에서 조용히 받아 둔다. 받아 둔 것은 다음에 열 때 반영된다.
   내용이 실제로 바뀌었으면 화면에 알린다.

   회차를 「자료 추가」로 직접 붙여 넣은 것은 브라우저 안(localStorage)에 남으므로
   본문이 갱신되어도 그대로 남는다. */
const CACHE = 'chaguan-v2';
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

/* 뒤에서 새 본문을 받아 캐시를 갈아 끼운다. 내용이 바뀌었으면 열려 있는 화면에 알린다. */
function refresh(req) {
  /* GitHub Pages는 10분짜리 캐시를 붙여 보낸다. 그대로 fetch하면 브라우저가
     그 캐시를 내주어, 갱신을 올려도 한동안 못 받는다. 매번 서버에 물어보게 한다.
     바뀐 것이 없으면 서버가 304로 답하므로 오가는 것은 거의 없다. */
  return fetch(new Request(req.url, { cache: 'no-cache' })).then(async (res) => {
    if (!res || !res.ok) return;
    const c = await caches.open(CACHE);
    const old = await c.match('./index.html');
    const oldTag = old && (old.headers.get('etag') || old.headers.get('last-modified'));
    const newTag = res.headers.get('etag') || res.headers.get('last-modified');
    await c.put('./index.html', res.clone());
    if (old && oldTag && newTag && oldTag !== newTag) {
      const cs = await self.clients.matchAll({ type: 'window' });
      cs.forEach((cl) => cl.postMessage({ type: 'update-ready' }));
    }
  }).catch(() => {});
}

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;

  const isDoc = req.mode === 'navigate' || req.destination === 'document';

  if (isDoc) {
    e.respondWith(
      caches.match('./index.html').then((cached) => {
        if (cached) {
          e.waitUntil(refresh(req));   // 화면은 캐시로 즉시 띄우고, 갱신은 뒤에서
          return cached;
        }
        return fetch(req).then((res) => {
          if (res.ok) {
            const copy = res.clone();
            caches.open(CACHE).then((c) => c.put('./index.html', copy));
          }
          return res;
        });
      })
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
