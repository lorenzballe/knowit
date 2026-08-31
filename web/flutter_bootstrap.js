// Serve the rendering engine from the deploy rather than from the gstatic
// CDN. It is about five megabytes: fetched from the same origin it arrives
// with everything else and is cached with the build, instead of being a
// separate cross-origin round trip on every cold load — and it still works on
// a network that blocks Google's CDN.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
