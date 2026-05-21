# Streaming Widgets Architectural Analysis: Stateful vs. Stateless

This document explains the underlying mechanics of `streaming_gen_ui` components. It details why some widgets require `StatefulWidget` wrappers with `didUpdateWidget` overrides while others remain `StatelessWidget`s, and proposes concrete architectural patterns to simplify widget definitions.

---

## 🏛️ 1. The Great Classification Matrix

The table below classifies the built-in streaming widgets and details their state requirements:

| Widget | Type | State Caching (`didUpdateWidget`) | Why? |
| :--- | :--- | :--- | :--- |
| **`StreamingColumn`** | `StatelessWidget` | ❌ None | Receives `childrenProperty` (extracted at the registry builder level) directly. Does not extract properties inside `build()`. |
| **`StreamingRow`** | `StatelessWidget` | ❌ None | Receives `childrenProperty` directly. |
| **`StreamingEntrance`** | `StatelessWidget` | ❌ None | Special utility widget. Does not read properties; it just coordinates standard entering animations for nested children. |
| **`StreamingText`** | `StatefulWidget` |  `!identical` | Extracts specific text properties (`label`, `content`) from a generic `props` map. Requires cache stability for typewriter continuity. |
| **`StreamingBadge`** | `StatefulWidget` |  `!identical` | Extracts `label` string property and custom HEX styles. Requires cache to prevent style flashing. |
| **`StreamingBox`** | `StatefulWidget` |  `!identical` | Extracts `child` map property and layout dimensions dynamically from `props`. |
| **`StreamingContainer`** | `StatefulWidget` |  `!identical` | Extracts nested children, heights, widths, and hex color properties from `props`. |
| **`StreamingElevatedButton`**| `StatefulWidget` |  `!identical` | Extracts action trigger futures and child widget layouts. |
| **`StreamingDataTable`** | `StatefulWidget` |  `!identical` | Extracts dynamic columns and row matrixes. |
| **`StreamingAgentStepper`** | `StatefulWidget` |  `!identical` | Tracks and caches dynamic step arrays and active execution indices. |

---

## 🔍 2. The Root Cause: Non-Idempotent Property Getters

The central mystery is: **"Why can't I just call property streams in `build()` and render them with standard implicit animation widgets or StreamBuilders?"**

### The Reference Identity Problem
Under the hood, the `llm_json_stream` package implements property queries as dynamic lookups. Calling `.getStringProperty('label')` or `.getMapProperty('child')` inside a map stream is **non-idempotent**. 

Every single time a getter is called, **it creates and returns a brand-new instance** of the `PropertyStream` wrapper object:

```
[Parent View State Updates]
          │
          ▼ (Triggers Rebuild)
[StreamingBadge.build()]
          │
          ├─► mapStream.getStringProperty('label') ────► returns: PropertyStream (Instance A)
          │
[Parent View State Updates Again (Next Character)]
          │
          ▼ (Triggers Rebuild)
[StreamingBadge.build()]
          │
          └─► mapStream.getStringProperty('label') ────► returns: PropertyStream (Instance B)
```

Because `Instance A` and `Instance B` reside at different memory addresses, `identical(StreamA, StreamB)` evaluates to **`false`**. 

### The Subscription Reset Disaster
If these getters are called directly inside a `StatelessWidget`'s `build()` method and passed to a `StreamBuilder` or `AccumulatingStringStreamBuilder`:

1.  Flutter's `StreamBuilder` detects a new stream reference in its `didUpdateWidget`.
2.  It immediately **unsubscribes** from the old stream and **subscribes** to the new one.
3.  This unsubscription forces the `StreamBuilder` to reset its connection state back to `ConnectionState.waiting`.
4.  **Result:** The UI suffers from extreme layout flickering, disappearing text blocks, and resets back to empty placeholders on every single incoming character token chunk.

### The Caching Solution
To eliminate this jank, we wrap these widgets in a `StatefulWidget` and freeze the property stream references inside `initState`:

```dart
class _StreamingBadgeState extends State<StreamingBadge> {
  late Stream<String> _labelStream;
  
  @override
  void initState() {
    super.initState();
    // 1. Freeze the property stream reference in State
    _labelStream = widget.props.asMap.getStringProperty("label").stream;
  }
}
```

Because `State` persists across parent rebuilds, the `build()` method now queries the **cached** `_labelStream` instance, keeping the subscription perfectly stable!

### The Role of `didUpdateWidget`
If the block changes or the view is restored, a completely new `widget.props` reference is passed down from `ViewState`. We must check if the reference shifted, and if so, refresh the cache:

```dart
@override
void didUpdateWidget(covariant StreamingBadge oldWidget) {
  super.didUpdateWidget(oldWidget);
  
  // 2. Only re-cache if the parent actually swapped the underlying block reference
  if (!identical(widget.props, oldWidget.props)) {
    _initStream(); 
  }
}
```

---

## 🛠️ 3. Why column and Row are Stateless

You noticed that `StreamingColumn` and `StreamingRow` are `StatelessWidget`s despite holding nested streaming children. 

This works because **their property extraction is performed inside their registry-level lambda function rather than their `build()` method**:

```dart
  // Inside core_registry.dart
  "core:column": WidgetDefinition(
    builder: (context, props) {
      // 1. Property stream is extracted ONCE inside the registry lambda
      final childrenProperty = props.asMap.getListProperty("children");
      
      // 2. The stable property is passed directly to the constructor
      return StreamingColumn(childrenProperty: childrenProperty);
    },
  )
```

When `StreamingWidget` rebuilds a `core:column`, Flutter checks if it can reuse the element. Since the lambda creates a new `StreamingColumn` instance, it compares the passed `childrenProperty`. If `childrenProperty`'s underlying stream reference changes, it updates the `StatelessWidget`. 

While this is functional, `StreamingColumn`'s `StreamBuilder` actually *does* re-subscribe if the registry lambda evaluates it to a different stream wrapper. The column survives this because its children are wrapped in `StreamingWidget` which use `ObjectKey(block)` to freeze their states, hiding any internal list resets!

---

## 💡 4. How Can We Simplify This?

We can simplify the widget definition process and eliminate boilerplate `StatefulWidget` structures using three architectural approaches:

### Proposal A: Idempotent Property Streams (Engine-Level Caching)
We can update the Map wrapper in `llm_json_stream` (or write a light wrapper on top of it) to cache property stream references internally:

```dart
class IdempotentMapPropertyStream {
  final MapPropertyStream _underlying;
  final Map<String, PropertyStream> _cachedProps = {};

  IdempotentMapPropertyStream(this._underlying);

  PropertyStream getStringProperty(String key) {
    return _cachedProps.putIfAbsent(key, () => _underlying.getStringProperty(key));
  }
}
```

If `getStringProperty` returns the **exact same instance** every time it is called, we can instantly rewrite **every single widget** as a 100% `StatelessWidget` with zero `didUpdateWidget` overrides!

### Proposal B: The `StreamingPropertyBuilder` Utility Widget
We can create a generalized helper widget that handles the caching, reference checks, and rebuilding automatically.

```dart
class StreamingPropertyBuilder<T> extends StatefulWidget {
  final PropertyStream props;
  final String propertyName;
  final T Function(PropertyStream prop) extractor;
  final Widget Function(BuildContext context, T extractedValue) builder;

  const StreamingPropertyBuilder({
    super.key,
    required this.props,
    required this.propertyName,
    required this.extractor,
    required this.builder,
  });

  @override
  State<StreamingPropertyBuilder<T>> createState() => _StreamingPropertyBuilderState<T>();
}

class _StreamingPropertyBuilderState<T> extends State<StreamingPropertyBuilder<T>> {
  late T _cachedValue;

  @override
  void initState() {
    super.initState();
    _cache();
  }

  @override
  void didUpdateWidget(covariant StreamingPropertyBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props) || widget.propertyName != oldWidget.propertyName) {
      _cache();
    }
  }

  void _cache() {
    _cachedValue = widget.extractor(widget.props);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _cachedValue);
  }
}
```

Using this utility, a custom badge becomes extremely clean and completely stateless:

```dart
class StreamingBadge extends StatelessWidget {
  final PropertyStream props;
  const StreamingBadge({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return StreamingPropertyBuilder<PropertyStream>(
      props: props,
      propertyName: 'label',
      extractor: (p) => p.asMap.getStringProperty('label'),
      builder: (context, labelProp) {
        return StreamingText(
          props: labelProp,
          builder: (context, text) => Badge(label: Text(text)),
        );
      },
    );
  }
}
```

### Proposal C: Composition of Leaf Primitives (100% Stateless Custom Widgets)
When building custom domain widgets, developers can keep their widgets 100% stateless by avoiding direct stream access and instead nesting our built-in `StreamingText` and `StreamingWidget` primitives.

For example, a custom hotel card widget can be built entirely as a `StatelessWidget`:

```dart
class HotelCard extends StatelessWidget {
  final PropertyStream props;

  const HotelCard({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    final map = props.asMap;

    return Card(
      child: Column(
        children: [
          // 1. StreamingText handles string caching and typewriter under the hood
          StreamingText(
            props: map.getStringProperty('name'),
            builder: (context, name) => Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          StreamingText(
            props: map.getStringProperty('price'),
            builder: (context, price) => Text('$$price / night'),
          ),
          // 2. StreamingWidget recursively handles nested layouts
          StreamingWidget(
            props: map.getMapProperty('ratingWidget'),
          ),
        ],
      ),
    );
  }
}
```
This composition pattern is highly recommended for developers as it completely hides streams, futures, subscriptions, and `didUpdateWidget` lifecycle complexities.

---

## 🔬 5. Deep-Dive Q&A: Under the Hood

### Q1: What exactly does `didUpdateWidget` do under the hood, and what happens with vs. without it?

#### 🟥 Without `didUpdateWidget`
Suppose a user changes views or sends a brand-new chat message that triggers a completely different stream.
1. The Flutter framework determines it can reuse the existing `State` object since the widget's runtime type (`StreamingBadge`) and keys are compatible.
2. The parent widget instantiates the new `StreamingBadge` widget with the new `props`, but preserves the old `_StreamingBadgeState` instance.
3. Because `initState()` is **only called once** in the entire lifespan of a `State` object (when it is first mounted), **the fields inside the state (`_labelStream` and `_badgeStream`) still hold references to the old message block's property streams**.
4. The widget's `build()` method executes using the cached `_labelStream` (which belongs to the *first* message's props).
5. **Result:** The UI will completely ignore any updates or streams from the new message block! It will freeze and fail to receive any new chunks.

#### 🟩 With `didUpdateWidget`
This lifecycle method is called by Flutter whenever the parent widget rebuilds and updates the widget instance associated with this `State` object.
```dart
@override
void didUpdateWidget(covariant StreamingBadge oldWidget) {
  super.didUpdateWidget(oldWidget);
  
  // If the parent passed a new props reference, re-extract and cache the streams!
  if (!identical(widget.props, oldWidget.props)) {
    _initStream();
  }
}
```
Now, when the parent passes a new `props` object, we discard the old cached streams and initialize listening to the new block's streams, updating the UI dynamically.

---

### Q2: Why are some conditionals expanded to check both `props` and other fields?

In some widgets, the conditional is expanded (e.g. `!identical(widget.props, oldWidget.props) || widget.propertyName != oldWidget.propertyName`).

This is because a widget's behavior can be driven by other parameters too. For example, if you reuse a `StreamingText` widget state, but change its `propertyName` from `'title'` to `'subtitle'`, we must re-run `_initStream()` to extract the `'subtitle'` stream. If we only checked `!identical(widget.props, oldWidget.props)`, changing `propertyName` while keeping `props` the same would fail to refresh the cached stream!

---

### Q3: The Idempotency Debate: Native `llm_json_stream` vs. `StreamingPropertyBuilder`

If you are the author of `llm_json_stream`, here is the breakdown of how to solve this at the core library level:

#### Option A: Native Caching inside `llm_json_stream` (Idempotent Getters)
Make `mapStream.getStringProperty('key')` idempotent by storing and returning the identical `PropertyStream` instance inside an internal map.

*   **Pros:**
    *   **Stateless Magic:** Custom widgets can immediately become 100% `StatelessWidget`s. Developers can call getters directly inside `build()` without any subscription reset or flicker!
    *   **Ecosystem Cleanliness:** Cures the "flickering trap" natively for anyone using your library.
*   **Cons:**
    *   *Memory Retention:* The map must hold references to child property streams until the parent stream is closed. In standard LLM payloads, this is negligible.

#### Option B: The `StreamingPropertyBuilder` Utility Widget
Create a custom generic helper widget inside `streaming_gen_ui` to cache the streams.

*   **Pros:** Zero risk of breaking other projects using `llm_json_stream`.
*   **Cons:** Adds boilerplate nesting (`StreamingPropertyBuilder(...)`) to every custom stateless widget.

**Recommendation:** It is highly recommended to update `llm_json_stream` to be natively idempotent! In declarative frameworks, caching properties internally is the most natural, intuitive developer experience.

---

### Q4: The Cons and Trade-offs of Proposal C (Leaf Primitive Composition)

While Proposal C (nesting `StreamingText` and `StreamingWidget` inside stateless custom widgets) is exceptionally clean, it has two minor trade-offs:

1.  **Conditional Styling & Logic Limits:** If you need to perform calculations or conditional styling based on a dynamic property *before* rendering it, Proposal C makes it slightly trickier.
    *   *Example:* If you want to show a checkmark icon only if a boolean property `isAvailable` is `true`. Since `isAvailable` is streamed, you cannot simply write `if (map.getBooleanProperty('isAvailable').value == true)` inside `build()` because the value is highly dynamic.
    *   *Resolution:* You must wrap that conditional check in a standard `StreamBuilder`, introducing a bit of boilerplate.
2.  **Builder Tree Nesting:** Each primitive has its own `StreamBuilder` and `Stateful` element under the hood. For extremely dense layouts (e.g., a grid with 50 items each having 10 text fields), this creates more widget elements in the tree compared to a single parent map `StreamBuilder` repaint. In Flutter, this is highly optimized and rarely a bottleneck, but it is technically heavier.
