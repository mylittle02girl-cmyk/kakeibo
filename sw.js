// オフライン用のService Worker（キャッシュ優先）。index.html を変えたら CACHE の番号を上げること
const CACHE = "kakeibo-v2-6";
const FILES = ["./", "index.html", "manifest.json", "icon-180.png", "icon-512.png"];

self.addEventListener("install", ev => {
  ev.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", ev => {
  ev.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", ev => {
  const req = ev.request;
  if (req.method !== "GET" || new URL(req.url).origin !== location.origin) return;
  ev.respondWith(
    caches.match(req, {ignoreSearch: true}).then(hit => {
      if (hit) return hit;
      return fetch(req).then(res => {
        if (res && res.ok && res.type === "basic") {
          const copy = res.clone();
          caches.open(CACHE).then(c => c.put(req, copy));
        }
        return res;
      }).catch(() => req.mode === "navigate" ? caches.match("index.html") : Response.error());
    })
  );
});
