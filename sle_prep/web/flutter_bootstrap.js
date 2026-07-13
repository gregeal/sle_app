{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      // Flutter's CanvasKit renderer otherwise reaches fonts.gstatic.com for
      // fallback glyphs. Keep every runtime dependency on this origin so the
      // production CSP and offline exercise path remain deterministic.
      fontFallbackBaseUrl: "font-fallback/",
    });
    await appRunner.runApp();
  },
});
