/* SLE Prep application-shell service worker.
 * The production build replaces BUILD_ID_PLACEHOLDER with a deterministic
 * hash of this worker and every APP_SHELL file.
 * Auth and API responses are deliberately never cached.
 */
const CACHE_PREFIX = "sle-prep-shell-";
const CACHE_VERSION = `${CACHE_PREFIX}__SLE_PREP_BUILD_ID__`;
const IS_FINALIZED_BUILD = !CACHE_VERSION.includes(
  "__SLE_PREP_" + "BUILD_ID__",
);
const NAVIGATION_TIMEOUT_MS = 5_000;
const APP_SHELL = [
  "./",
  "./index.html",
  "./flutter.js",
  "./flutter_bootstrap.js",
  "./main.dart.js",
  "./manifest.json",
  "./version.json",
  "./passkeys.js",
  "./sqlite3.wasm",
  "./drift_worker.js",
  "./favicon.png",
  "./assets/AssetManifest.bin",
  "./assets/AssetManifest.bin.json",
  "./assets/FontManifest.json",
  "./assets/fonts/MaterialIcons-Regular.otf",
  "./assets/packages/cupertino_icons/assets/CupertinoIcons.ttf",
  "./assets/shaders/ink_sparkle.frag",
  "./assets/shaders/stretch_effect.frag",
  "./assets/assets/fonts/NotoSans-Variable.ttf",
  "./assets/assets/seed/curriculum.json",
  "./assets/assets/seed/drills_core.json",
  "./assets/assets/seed/oral_core.json",
  "./assets/assets/seed/reading_core.json",
  "./assets/assets/seed/vocab_core.json",
  "./canvaskit/canvaskit.js",
  "./canvaskit/canvaskit.wasm",
  "./canvaskit/chromium/canvaskit.js",
  "./canvaskit/chromium/canvaskit.wasm",
  "./icons/Icon-192.png",
  "./icons/Icon-512.png",
  "./icons/Icon-maskable-192.png",
  "./icons/Icon-maskable-512.png",
  "./font-fallback/notosanssymbols/v43/rP2up3q65FkAtHfwd-eIS2brbDN6gxP34F9jRRCe4W3gfQ8gb_VFRkzrbQ.woff2",
  "./font-fallback/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2",
];

const STATIC_ROOT_FILES = new Set([
  "favicon.png",
  "flutter.js",
  "flutter_bootstrap.js",
  "main.dart.js",
  "manifest.json",
  "version.json",
  "passkeys.js",
  "sqlite3.wasm",
  "drift_worker.js",
]);
const STATIC_DIRECTORIES = ["assets/", "canvaskit/", "font-fallback/", "icons/"];

const scopedPath = (url) => {
  const scopePath = new URL(self.registration.scope).pathname;
  if (!url.pathname.startsWith(scopePath)) return null;
  return url.pathname.slice(scopePath.length);
};

const isPrivateRoute = (path) => (
  path === "api" || path.startsWith("api/") ||
  path === "auth" || path.startsWith("auth/")
);

const isCacheableStatic = (path) => (
  STATIC_ROOT_FILES.has(path) ||
  STATIC_DIRECTORIES.some((prefix) => path.startsWith(prefix))
);

self.addEventListener("install", (event) => {
  if (!IS_FINALIZED_BUILD) {
    // Keep a previously valid worker active if someone deploys raw,
    // unfinalized Flutter output.
    event.waitUntil(Promise.reject(new Error("PWA build was not finalized")));
    return;
  }
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) => cache.addAll(
      APP_SHELL.map((path) => new Request(
        new URL(path, self.registration.scope),
        { cache: "reload", credentials: "same-origin" },
      )),
    )),
  );
});

self.addEventListener("message", (event) => {
  if (event.data?.type === "SKIP_WAITING") {
    event.waitUntil(self.skipWaiting());
  }
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys
          .filter((key) => key.startsWith(CACHE_PREFIX) && key !== CACHE_VERSION)
          .map((key) => caches.delete(key)),
      ))
      .then(() => self.clients.claim()),
  );
});

const fetchWithTimeout = async (request) => {
  const controller = new AbortController();
  const abort = () => controller.abort();
  const timeout = setTimeout(abort, NAVIGATION_TIMEOUT_MS);
  request.signal.addEventListener("abort", abort, { once: true });
  try {
    return await fetch(request, { signal: controller.signal });
  } finally {
    clearTimeout(timeout);
    request.signal.removeEventListener("abort", abort);
  }
};

const networkFirstNavigation = async (request) => {
  const cache = await caches.open(CACHE_VERSION);
  try {
    const response = await fetchWithTimeout(request);
    if (response.ok && response.type === "basic") {
      await cache.put("./index.html", response.clone());
    }
    if (response.status >= 500) {
      return (await cache.match("./index.html")) || response;
    }
    return response;
  } catch (_) {
    return (await cache.match("./index.html")) || Response.error();
  }
};

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  const path = scopedPath(url);
  if (path === null || isPrivateRoute(path)) return;
  if (request.mode === "navigate") {
    event.respondWith(networkFirstNavigation(request));
    return;
  }
  // Cache only the app's immutable/static namespaces. This prevents an
  // unrelated same-origin GET response from becoming durable browser data.
  if (!isCacheableStatic(path)) return;
  event.respondWith(
    caches.open(CACHE_VERSION).then(async (cache) => {
      const cached = await cache.match(request);
      if (cached) return cached;
      const response = await fetch(request);
      if (response.ok && response.type === "basic") {
        await cache.put(request, response.clone());
      }
      return response;
    }),
  );
});
