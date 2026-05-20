# Widget Registries & Set-Theory Composition

This specification defines the architecture for organizing, packaging, and composing built-in and custom widgets inside the `streaming_gen_ui` library.

---

## 🏛️ The Core Philosophy: Population vs. Sets

To solve prompt-synchronization drift, eliminate file bloat, and allow clean package composition, this framework separates **Widget Implementation** from **Registry Bundling**:

```
 ┌──────────────────────────────────────────────────────────┐
 │                  THE POPULATION DATABASE                 │
 │  (Individual, unique, unsorted WidgetDefinitions in lib) │
 │                                                          │
 │     core:text       core:column      core:row            │
 │     core:container  core:textfield   core:button         │
 └───────────────────────────┬──────────────────────────────┘
                             │
                             ├──────────────────────┐
                             ▼                      ▼
                    ┌─────────────────┐   ┌─────────────────┐
                    │   REGISTRY SET  │   │   REGISTRY SET  │
                    │  (Foundational) │   │  (Interactive)  │
                    └────────┬────────┘   └────────┬────────┘
                             │                     │
                             └──────────┬──────────┘
                                        ▼
                               ┌─────────────────┐
                               │   MERGED SET    │
                               │   (Essentials)  │
                               └─────────────────┘
```

1. **The Population (The Elements):**
   * Individual `WidgetDefinition` instances representing the concrete building blocks (located inside `lib/src/widgets/core/`).
   * They exist exactly **once** in the codebase.
2. **The Registries (The Sets):**
   * A `WidgetRegistry` is simply a **Set of references** pointing to the population database.
   * Multiple registries can reference the exact same population elements without duplication.

### 🧩 Widget Definitions & Live Catalog Previews

Every concrete widget in the population is defined by a `WidgetDefinition` structure containing its builder function, schema constraints, and an illustrative JSON example:

```dart
class WidgetDefinition {
  final WidgetBuilderFunction builder;
  final String description;
  final Map<String, String> properties;
  final String jsonExample; // <-- Critical for streaming catalog previews
}
```

#### The `jsonExample` Streaming Preview Pattern

The `jsonExample` field serves two primary roles:
1. **Developer Reference & Prompt Compilation:** It represents the exact JSON schema the LLM is expected to generate when emitting this widget.
2. **Catalog Live Simulation:** Rather than presenting a static component in the widget catalog, the catalog page uses the `jsonExample` to simulate a real-world streaming experience. The engine reads the `jsonExample` string, splits it into micro-chunks (e.g., character-by-character or small token sequences), and feeds this raw chunked stream directly into the generative UI engine. This allows developers to verify and inspect the widget's transitional animations, skeleton shimmers, and progressive layout morphing (Continuous State Morphing) in real-time, exactly as an end-user would experience it.

---

## ➕ Dynamic Set Math & Composition API

To make composing, filtering, and customizing registries effortless, the `WidgetRegistry` class supports standard **Set Theory operators** in Dart:

### 1. Union (`+` Operator)
Combines two registries together, automatically merging their elements.
```dart
WidgetRegistry operator +(WidgetRegistry other) {
  return WidgetRegistry(widgets: {
    ...widgets,
    ...other.widgets,
  });
}
```
* **Collision Resolution:** If both sets contain `"core:row"`, merging them via `+` resolves gracefully to the identical reference, with **zero conflicts** or runtime overhead.

### 2. Subset Selection (`only()`)
Derives a new sub-registry containing only a select list of widget IDs.
```dart
WidgetRegistry only(List<String> ids) {
  final filtered = <String, WidgetDefinition>{};
  for (final id in ids) {
    if (widgets.containsKey(id)) {
      filtered[id] = widgets[id]!;
    }
  }
  return WidgetRegistry(widgets: filtered);
}
```

### 3. Subtraction (`without()`)
Removes a select list of widget IDs from an existing registry.
```dart
WidgetRegistry without(List<String> ids) {
  final filtered = Map<String, WidgetDefinition>.from(widgets);
  for (final id in ids) {
    filtered.remove(id);
  }
  return WidgetRegistry(widgets: filtered);
}
```

---

## 📦 Bundled Registry Ecosystem (`Registries`)

The `Registries` class serves as the entrypoint for built-in bundles. It exposes static getters that construct specialized registry sets dynamically:

```dart
class Registries {
  /// Base layout widgets (Column, Row, Container)
  static WidgetRegistry get layout => WidgetRegistry(widgets: {
    "core:column": coreWidgets["core:column"]!,
    "core:row": coreWidgets["core:row"]!,
    "core:container": coreWidgets["core:container"]!,
  });

  /// User interaction widgets (Button, TextField)
  static WidgetRegistry get interactive => WidgetRegistry(widgets: {
    "core:elevated_button": coreWidgets["core:elevated_button"]!,
    "core:textfield": coreWidgets["core:textfield"]!,
  });

  /// The essential package (Layout + basic typography)
  /// Composed elegantly via Union (+) math
  static WidgetRegistry get essentials => layout + WidgetRegistry(widgets: {
    "core:text": coreWidgets["core:text"]!,
  });
}
```

---

## 💎 Developer Integration Patterns

### A. The Curated Setup (Default Essentials)
For standard chat applications that require layout structure and dynamic forms:
```dart
final genUi = StreamingGenerativeUi(
  registry: Registries.essentials + Registries.interactive,
);
```

### B. The Read-Only Setup
For displaying parsed dashboard cards while locking out all interactive inputs:
```dart
final genUi = StreamingGenerativeUi(
  registry: Registries.essentials.without(["core:elevated_button", "core:textfield"]),
);
```

### C. Seamless Merging with Custom Domain Widgets
Registering custom widgets alongside prepackaged built-ins:
```dart
final customRegistry = WidgetRegistry(widgets: {
  "custom:user_profile": WidgetDefinition(...),
  "custom:hotel_card": WidgetDefinition(...),
});

// Fluent composition
final finalRegistry = Registries.essentials + customRegistry;
```
