/* 스틸링고 Lite — 서비스워커

   글꼴과 음성을 파일 밖으로 뺀 뒤로 본문 HTML은 140KB 남짓이다.
   그래서 열 때마다 새것을 받아도 느리지 않다. 매번 최신을 먼저 받아
   그 자리에서 반영한다.

   다만 지하철처럼 느린 곳에서 하염없이 기다리게 둘 수는 없다.
   2.5초 안에 오지 않으면 저장해 둔 것으로 먼저 열고, 늦게 도착한 새것은
   캐시에 넣어 둔다(그때는 화면에 한 줄 알린다).

   글꼴·음성은 내용이 바뀌지 않으므로 캐시를 먼저 쓴다. */
const CACHE = 'steel-lingo-lite-v13';
const DOC_TIMEOUT = 2500;
const SHELL = [
  './index.html', './manifest.json', './icon-192.png', './icon-512.png',
  /* 글꼴은 화면에 바로 필요하므로 미리 받아 둔다. 음성은 누를 때 받아서 캐시한다. */
  './fonts/f1.woff2', './fonts/f2.woff2', './fonts/f3.woff2', './fonts/f4.woff2', './fonts/f5.woff2'
];

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

/* 받아 온 본문을 캐시에 넣는다. 내용이 실제로 바뀌었으면 true를 돌려준다. */
async function putDoc(res) {
  const c = await caches.open(CACHE);
  const old = await c.match('./index.html');
  const oldTag = old && (old.headers.get('etag') || old.headers.get('last-modified'));
  const newTag = res.headers.get('etag') || res.headers.get('last-modified');
  await c.put('./index.html', res.clone());
  return !!(old && oldTag && newTag && oldTag !== newTag);
}

/* 본문은 네트워크를 먼저 본다. 늦으면 저장본으로 연다. */
function docStrategy(req) {
  return new Promise((resolve) => {
    let answered = false;
    const finish = (r) => { if (!answered) { answered = true; resolve(r); } };

    const timer = setTimeout(() => {
      caches.match('./index.html').then((c) => { if (c) finish(c); });
    }, DOC_TIMEOUT);

    fetch(req).then(async (res) => {
      if (!res || !res.ok) throw new Error('bad response');
      const changed = await putDoc(res);
      clearTimeout(timer);
      if (answered && changed) {
        // 이미 저장본으로 열린 뒤에 새것이 도착한 경우에만 알린다
        const cs = await self.clients.matchAll({ type: 'window' });
        cs.forEach((cl) => cl.postMessage({ type: 'update-ready' }));
      }
      finish(res);
    }).catch(async () => {
      clearTimeout(timer);
      const cached = await caches.match('./index.html');
      finish(cached || Response.error());
    });
  });
}

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;

  if (req.mode === 'navigate' || req.destination === 'document') {
    e.respondWith(docStrategy(req));
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
