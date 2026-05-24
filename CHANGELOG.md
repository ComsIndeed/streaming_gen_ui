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
