{{flutter_js}}
{{flutter_build_config}}

const loading = document.getElementById("sle-loading");
const updateNotice = document.getElementById("sle-update");
const updateButton = document.getElementById("sle-update-button");
let offlineRegistration;
let reloadScheduled = false;

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.addEventListener("controllerchange", () => {
    if (!reloadScheduled) return;
    reloadScheduled = false;
    window.location.reload();
  });
}

updateButton?.addEventListener("click", () => {
  const waitingWorker = offlineRegistration?.waiting;
  if (!waitingWorker) {
    window.location.reload();
    return;
  }
  reloadScheduled = true;
  updateButton.disabled = true;
  updateButton.textContent = "Mise à jour…";
  waitingWorker.postMessage({ type: "SKIP_WAITING" });
});

const showStartupError = (error) => {
  if (!loading) return;
  loading.setAttribute("role", "alert");
  loading.setAttribute("data-error", "true");
  loading.innerHTML = `
    <h1>Impossible de démarrer SLE Prep</h1>
    <p>Vérifiez la connexion ou le stockage du navigateur, puis réessayez.</p>
    <button type="button">Réessayer</button>
  `;
  loading.querySelector("button")?.addEventListener(
    "click",
    () => window.location.reload(),
  );
  console.error("SLE Prep startup failed", error);
};

const showUpdateWhenInstalled = (worker) => {
  const showIfWaiting = () => {
    if (worker.state === "installed" && navigator.serviceWorker.controller) {
      updateNotice?.removeAttribute("hidden");
    }
  };
  worker.addEventListener("statechange", showIfWaiting);
  showIfWaiting();
};

const registerOfflineShell = async () => {
  if (!("serviceWorker" in navigator)) return;
  const workerUrl = new URL("sle_prep_sw.js", document.baseURI);
  const workerResponse = await fetch(workerUrl, {
    cache: "no-store",
    credentials: "same-origin",
  });
  if (!workerResponse.ok) {
    throw new Error(`Service worker returned ${workerResponse.status}`);
  }
  if ((await workerResponse.text()).includes("__SLE_PREP_BUILD_ID__")) {
    // `flutter run` and an unfinalized manual build stay online-only instead
    // of installing a cache that can never invalidate reliably.
    console.info("Offline shell skipped for an unfinalized build");
    return;
  }
  const registration = await navigator.serviceWorker.register(
    workerUrl,
    { scope: "./", updateViaCache: "none" },
  );
  offlineRegistration = registration;
  if (registration.waiting && navigator.serviceWorker.controller) {
    updateNotice?.removeAttribute("hidden");
  }
  if (registration.installing) {
    showUpdateWhenInstalled(registration.installing);
  }
  registration.addEventListener("updatefound", () => {
    if (registration.installing) {
      showUpdateWhenInstalled(registration.installing);
    }
  });
};

registerOfflineShell().catch((error) => {
  // Offline installation is progressive enhancement; the online app still runs.
  console.warn("Offline shell registration failed", error);
});

const startFlutter = () => new Promise((resolve, reject) => {
  let settled = false;
  const timeout = window.setTimeout(
    () => fail(new Error("Flutter entrypoint timed out")),
    60_000,
  );
  const onResourceError = (event) => {
    const target = event.target;
    if (target?.tagName === "SCRIPT" && target.src?.endsWith("/main.dart.js")) {
      fail(new Error("main.dart.js could not be loaded"));
    }
  };
  const cleanup = () => {
    window.clearTimeout(timeout);
    window.removeEventListener("error", onResourceError, true);
  };
  const succeed = () => {
    if (settled) return;
    settled = true;
    cleanup();
    resolve();
  };
  function fail(error) {
    if (settled) return;
    settled = true;
    cleanup();
    reject(error);
  }

  // The callback form is Flutter's supported customization path. A captured
  // resource error and timeout cover the loader's otherwise silent script-tag
  // failure path.
  window.addEventListener("error", onResourceError, true);
  _flutter.loader.load({
    onEntrypointLoaded: async (engineInitializer) => {
      if (settled) return;
      try {
        const appRunner = await engineInitializer.initializeEngine({
          // Keep runtime font dependencies on this origin for CSP/offline use.
          fontFallbackBaseUrl: "font-fallback/",
        });
        await appRunner.runApp();
        loading?.remove();
        succeed();
      } catch (error) {
        fail(error);
      }
    },
  }).catch(fail);
});

startFlutter().catch(showStartupError);
