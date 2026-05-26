# Streaming Gen UI Roadmap & TODOs

This file tracks the next steps and long-term improvements for our streaming Generative UI system.

## 🎯 High-Level Plan / Future Actions

- [ ] **Non-Animated View Renderer (`view()` getter or option)**
  - Create a new widget getter method or parameter on `StreamingGenerativeUi.view()` to allow rendering without animations (e.g. `animate: false` or a separate `staticView()` method).
  - This is optimized for displaying historic chat messages that are already done streaming, preventing unnecessary entry/exit transitions and resource usage when scrolling or rebuilding older list items.
  
- [ ] **Stream Optimization for Completed History (`stream()` bypass)**
  - Implement a new direct injection method in `StreamingGenerativeUi` to register a fully completed raw string directly into the ViewState without running the asynchronous tag parser streams.
  - This bypasses stream setup overhead entirely for historical messages, significantly improving layout speed on initial app load.

- [ ] **Aesthetic Segmented Registries**
  - Gradually introduce lightweight custom component templates and test them against the simplified XML parsing format.
  - Optimize the prompt structure to minimize the token footprint of schemas.
