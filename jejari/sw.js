/* 제자리 · 서비스워커

   처음 열 때 앱 파일 전부를 저장해 두고, 그다음부터는 인터넷 없이 저장본으로 연다.
   위기 화면도 저장본에 들어 있으므로 연결이 끊겨도 열린다.

   새 버전을 올릴 때는 CACHE의 숫자를 반드시 올린다. 그래야 브라우저가 바뀐 것을 알아챈다.
   새 버전은 받아 두기만 하고 바로 바꾸지 않는다. 호흡 중에 화면이 바뀌면 안 되기 때문이다.
   앱을 다시 열 때 화면 쪽이 'skip-waiting'을 보내면 그때 갈아 끼운다. */
const CACHE = 'jejari-v1';
const ASSETS = [
  './',
  './index.html',
  './manifest.webmanifest',
  './css/app.css',
  './js/app.js',
  './js/content.js',
  './js/store.js',
  './icons/icon.svg',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/maskable-512.png',
  './icons/apple-touch-icon.png',
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE).then((c) => Promise.all(
      ASSETS.map((u) => fetch(new Request(u, { cache: 'reload' })).then((res) => { if (res.ok) return c.put(u, res); }))
    ))
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k.startsWith('jejari-') && k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('message', (e) => {
  if (e.data && e.data.type === 'skip-waiting') self.skipWaiting();
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== location.origin) return;
  if (req.mode === 'navigate') {
    e.respondWith(
      caches.match('./index.html').then((hit) => hit || fetch(req))
    );
    return;
  }
  e.respondWith(
    caches.match(req, { ignoreSearch: true }).then((hit) => hit || fetch(req).then((res) => {
      if (res.ok) { const copy = res.clone(); caches.open(CACHE).then((c) => c.put(req, copy)); }
      return res;
    }))
  );
});
