# 🛠️ Widget Catalog & Chat Demo Tasks

This document tracks planned features, enhancements, and interactive polished tasks for the `streaming_gen_ui` widget catalog and AI playground.

## 📺 1. Media & Streaming Architecture
- [ ] **Universal Media Component:** Build a single component supporting images, videos, and audios that can stream.
- [ ] **Developer DX simplification:** Extract internal boilerplate so standard developers can create new streaming widgets without deep-dive overrides.

## 🌀 2. Animations & Timing
- [ ] **Infinite Loop Easing:** Adjust breathing and text glow cycles to loop organically with brief custom delays.

## 🎛️ 3. Sandbox Interactive Controls (Preview Page)
- [ ] **Debounced Real-Time Playground Updates:** Synchronize property editing fields to restart/re-stream layout animations instantly upon user input.
- [ ] **Syntax Highlighting:** Add high-craft styling to `<interface>` tags and JSON output displays.
- [ ] **Rich Properties Input UI:** Replace raw text inputs with interactive controls (Color pickers, Sliders, Dropdowns, Segmented switches).
- [ ] **Playback Control Suite:** Add Stream Start, Pause, and Reset buttons.
- [ ] **Timeline Scrubber:** Implement a progress playback slider allowing users to scrub back and forth through compile animations.

## 🧭 4. Layout & Morphing Transitions (Chat Demo)
- [ ] **Sliding Nav Indicator:** Create a custom snapping capsule pill under active page headers (Widget Catalog / Chat Demo).
- [ ] **Sleek Mode Morphing:** Animate superelliptical chat panels when transitioning between input types.
- [ ] **Slide-in Canvas Layout:** Slide the big canvas viewport in from the right, shifting the chat thread column smoothly to the left.
- [ ] **Live OpenAI LLM Stream Integration:** Connect the client library to pipe true OpenAI tokens chunk-by-chunk into the interactive Chat and Canvas viewports.
