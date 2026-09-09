/* 스틸 워크 스타일 서비스 워커
   앱이 HTML 한 장이라 캐시 전략이 단순하다. 설치할 때 전부 받아두고,
   그다음부터는 캐시를 먼저 주되 뒤에서 조용히 새 판을 받아둔다(stale-while-revalidate).
   워크숍 현장에서 망이 끊겨도 열려야 하는 것이 이 앱의 전제다. */
const VER   = "steel-work-style-v3.1";
const ASSETS = [
  "./",
  "./index.html",
  "./manifest.json",
  "./icon.svg",
  "./icon-192.png",
  "./icon-512.png",
  "./icon-maskable-512.png"
];

self.addEventListener("install", e => {
  e.waitUntil(
    caches.open(VER)
      /* 하나라도 실패하면 설치 전체가 엎어지므로 개별로 담는다 */
      .then(c => Promise.all(ASSETS.map(u => c.add(u).catch(() => {}))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== VER).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET" || new URL(req.url).origin !== location.origin) return;

  e.respondWith(
    caches.match(req).then(hit => {
      const net = fetch(req).then(res => {
        if (res && res.ok) caches.open(VER).then(c => c.put(req, res.clone()));
        return res;
      }).catch(() => hit || caches.match("./index.html"));
      return hit || net;
    })
  );
});
