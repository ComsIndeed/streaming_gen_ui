# Streaming Gen UI Roadmap & TODOs

This file tracks the next steps and long-term improvements for our streaming
Generative UI system.

## 🎯 High-Level Plan / Future Actions

- [ ] **Non-Animated View Renderer (`view()` getter or option)**
  - Create a new widget getter method or parameter on
    `StreamingGenerativeUi.view()` to allow rendering without animations (e.g.
    `animate: false` or a separate `staticView()` method).
  - This is optimized for displaying historic chat messages that are already
    done streaming, preventing unnecessary entry/exit transitions and resource
    usage when scrolling or rebuilding older list items.

- [ ] XML formatting
  - [ ] **Strict Dot-Notation Namespaces**: Enforce deterministic tag names matching the provider/namespace structure (e.g., `<Core.Text />` for `core:text`, `<MaterialUi.Card />` for `material_ui:card`, `<CoreExtended.IconButton />` for `core_extended:icon_button`).
    - *Benefits*: Perfect disk persistence stability (saved XML never breaks), zero collisions, zero complex guessing logic, native to LLM JSX training.
  - [ ] **Unified Property Resolution**: Properties are strictly parsed from tag attributes using `.getAttributeStream()` and `.getAttributeFuture()`.
  - [ ] **Tag Nesting Hierarchy**: Inner children are strictly reserved for visual layout nesting (e.g., `<Core.Column><MaterialUi.Card /></Core.Column>`). No dualities/fallback casing.
  - [ ] **Robust Tag Tolerance**: Seamless parsing of incomplete, streaming tags (`<tag`, `<tag>`, `<tag />`).


- [ ] Codeblock "`json`" tolerance

- [ ] **Contextual Schema Pruning (Split Responsibilities)**
  - Instead of listing all 12 schemas in the prompt at once, prune schemas dynamically before calling the model based on the user's message context.
  - Implement a simple keyword or cheap embeddings router to check user input and only inject the specific 1 or 2 component schemas they actually need.
  - *Benefits*: Prevents choice paralysis for 0.8B models, saves massive token/caching context, and makes schema parsing much more robust.


