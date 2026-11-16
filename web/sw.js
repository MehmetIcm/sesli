// Sesli — çevrimdışı önbellek.
//
// Uygulama kabuğu, WASM motoru ve model dosyaları ilk yüklemede tarayıcı
// önbelleğine alınır; sonraki açılışlar ağ olmadan çalışır. Model ~143 MB
// olduğu için kurulum sırasında topluca indirmek yerine ilk kullanımda
// (motor başlatılırken) önbelleğe alınır.
const CACHE_NAME = 'sesli-cache-v11';

// Uygulama kabuğu dosyaları her açılışta ağdan doğrulanır; böylece yeni
// sürüm yayınlandığında tarayıcı eski JavaScript'i çalıştırmaya devam
// etmez. Ağ yoksa önbellekteki kopya kullanılır.
const APP_SHELL_PATTERN =
    /\/(index\.html|flutter_bootstrap\.js|flutter\.js|main\.dart\.js|version\.json|manifest\.json|tts-worker\.js)$/;

const CORE_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './favicon.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './main.dart.js',
  './flutter_bootstrap.js',
  './flutter.js',
  './canvaskit/canvaskit.js',
  './canvaskit/canvaskit.wasm',
  './canvaskit/chromium/canvaskit.js',
  './canvaskit/chromium/canvaskit.wasm',
  './tts-worker.js',
  './assets/FontManifest.json',
  './assets/AssetManifest.bin.json',
  './assets/fonts/MaterialIcons-Regular.otf',
  './assets/fonts/fallback/Roboto-Regular.ttf',
  './assets/assets/fonts/Manrope.ttf',
  './assets/assets/data/english_lexicon.json',
  './assets/assets/data/turkish_words.txt',
  './assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  './assets/packages/sherpa_onnx_web/assets/sherpa-onnx-wasm-web.js',
  './assets/packages/sherpa_onnx_web/assets/sherpa-onnx-tts.js',
  './assets/packages/sherpa_onnx_web/assets/sherpa-onnx-wasm-web.wasm',
  './assets/assets/voices/female_1.wav',
  './assets/assets/voices/female_2.wav',
  './assets/assets/voices/female_3.wav',
  './assets/assets/voices/male_1.wav',
  './assets/assets/voices/male_2.wav',
  './assets/assets/voices/male_3.wav',
  './assets/assets/previews/female_1.wav',
  './assets/assets/previews/female_2.wav',
  './assets/assets/previews/female_3.wav',
  './assets/assets/previews/male_1.wav',
  './assets/assets/previews/male_2.wav',
  './assets/assets/previews/male_3.wav',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      // Kabuk dosyaları bulunamazsa kurulumu bozmayalım.
      await Promise.all(
        CORE_ASSETS.map(async (url) => {
          try {
            const response = await fetch(url, { cache: 'reload' });
            if (response.ok) await cache.put(url, response);
          } catch (_) {
            // Çevrimdışı kurulumda yok say.
          }
        }),
      );
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys
          .filter((key) => key.startsWith('sesli-cache-') && key !== CACHE_NAME)
          .map((key) => caches.delete(key)),
      );
      await self.clients.claim();
    })(),
  );
});

async function networkFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  try {
    const response = await fetch(request);
    if (response.ok) {
      cache.put(request, response.clone());
      return response;
    }
    // Geliştirme proxy'si veya sunucu çevrimdışıyken 502 dönebilir;
    // bu durumda önbellekteki uygulama kabuğunu kullan.
    const cached = await cache.match(request);
    if (cached) return cached;
    const shell = await cache.match('./index.html');
    if (shell) return shell;
    return response;
  } catch (error) {
    const cached = await cache.match(request);
    if (cached) return cached;
    const shell = await cache.match('./index.html');
    if (shell) return shell;
    throw error;
  }
}

async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);
  if (cached) return cached;

  const response = await fetch(request);
  // Yalnızca başarılı, aynı kaynaklı yanıtları sakla.
  if (response.ok && response.type === 'basic') {
    cache.put(request, response.clone());
  }
  return response;
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  // Menzil istekleri (ses/video akışı) önbelleğe uygun değil.
  if (request.headers.has('range')) return;

  if (request.mode === 'navigate' || APP_SHELL_PATTERN.test(url.pathname)) {
    event.respondWith(networkFirst(request));
    return;
  }

  event.respondWith(cacheFirst(request));
});
