## 0.2.2

### Performance Improvements & Optimization

- **Zero-Frame Synchronous Hydration (`AdaptiveStreamBuilder`)** — Replaces standard `StreamBuilder` in all themed cards. Avoids the 1-frame async microtask rendering delay by synchronously listening to immediate cached stream emissions and falling back to provider-level properties map on frame 1, eliminating mounting flickers and layout shifts when viewing completed/historical messages.
- **Adaptive Height Snapping (`AdaptiveAnimatedSize`)** — Replaces standard `AnimatedSize` across cards and layout structures. If a card is completed or animations are disabled, it immediately snaps to the final layout boundaries on frame 1, completely resolving the animation loop layout crash (`RenderAnimatedSize was mutated in its own performLayout implementation`) during fast list scroll operations.
- **Synchronous Future-Bypassing (`WidgetBlock`)** — Avoids asynchronous `FutureBuilder` lookup for resolved widget namespaces once the LLM stream completes.
- **Flat Multi-Stream Coordination (`AdaptiveMultiStreamBuilder`)** — Utility to flatly coordinate and merge multiple property streams without nesting.

### Bug Fixes

- Fixed demo list scroll jank by re-enabling scrollbars and locking rendering boundaries in the catalog chat page.

---

## 0.2.1


### New Features

- **Progressive Graph Bar Rendering** — The bargraph widget now uses the `.onElement` stream listener on the values and labels lists, progressively rendering elements and animating bars immediately as numbers start appearing, rather than waiting for the entire list to finish.

### Bug Fixes

- Fixed **Graph Null/Type Cast Exception** — Handled `type 'Null' is not a subtype of type 'num' in type cast` crash on list properties during active streams by using robust `.whereType<num>()` filtering.
- Fixed **Streaming Image Network URL API Errors** — `BaseStreamingImage` now accepts a `PropertyStream` and asynchronously awaits the fully resolved/completed `imageUrl` stream via `FutureBuilder`, preventing crashes caused by intermediate, partially streamed invalid URLs.
- Updated **Widget Catalog Integration Instructions** — Fixed old arithmetic `+` registry constructor instructions to utilize the correct list-based `.only()` filters.

---

## 0.2.0

### Breaking Changes

- **`registry:` → `registries:`** — `StreamingGenerativeUi` constructor now takes
  `List<WidgetRegistry> registries` instead of a single `WidgetRegistry registry`.
  Registry merging is handled internally via the `+` operator.

- **Widget registry overhaul** — The old flat `Registries.*` names (`layout`,
  `display`, `cards`, `status`, `advanced`, `dashboard`, `base`, `full`) have been
  replaced with a new theme-oriented structure. Backwards-compat aliases (`layout`,
  `core`, `essentials`) are kept but may be removed in a future release.

### New Features

#### Registry Architecture

- New segmented registries: `Registries.primitives`, `Registries.extended`
- New aesthetic theme registries: `Registries.material`, `Registries.fluent`,
  `Registries.apple`, `Registries.glassmorphic`, `Registries.neumorphic`,
  `Registries.skeumorphic`, `Registries.brutalist`
- `Registries.all` — master bundle of all themes + primitives + extended
- `Registries.forThemes(Set<String>, {bool includePrimitives})` — compose a
  registry from a specific set of theme names

#### New Constructor Parameters

- `extraInstructions: List<String>` — appends numbered custom instructions to
  the generated system prompt
- `customViewIds: Map<String, String>` — injects named view zone descriptions
  into the system prompt

#### New Methods

- `updateRegistry` / `updateRegistries` — swap the active registry in-place
- `hasContent(viewId)` — check if a view has any rendered content blocks
- `disposeView(viewId)` — free memory for a specific view

#### Render Anywhere

- `<interface viewId="...">` attribute support — the LLM can now target named
  view zones anywhere in the widget tree, not just the default chat stream.
  Define zones via `customViewIds` and place `streamingGenUi.view('zone-id')`
  anywhere in your widget tree.

### Bug Fixes

- Fixed **chunk-dropping bug** — switched from broadcast `StreamController` to
  single-subscription `StreamController`
- Fixed **memory leak and stop-rendering bug** — active stream subscriptions and
  controllers are now properly cancelled and closed on reset
- Fixed **first characters of the starting text block being dropped**
- Fixed **custom error block affecting non-streaming widgets**

### Improvements

- All themed card widgets wrapped in `AnimatedSize` for smooth streaming growth
- Streaming images render more reliably

---

## 0.1.0

* Initial stable release of the high-performance streaming Generative UI engine for Flutter.
* Real-time character-by-character UI component compilation and painting directly from raw LLM token feeds.
* Tag-based stream multiplexing supporting conversational Markdown text interleaved with dynamic `<interface>` widgets.
* State preservation and anti-flicker architecture using memory-safe reference stability, broadcast stream caching, and `ObjectKey` tree reconciliation.
* Composed set-theory registry bundles (`Registries.essentials`, `Registries.interactive`, `Registries.core`).
