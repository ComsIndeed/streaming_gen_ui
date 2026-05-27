User: Help me design a small agentic framework tailored towards smaller models.

Here are the requirements:

- Must work with very small models (Qwen 3.5 0.8B)

- Can embed UI by inserting <interface> tags into its response (I've got this
  handled, I know this)
- Tooling + The agentic loop where the model goes back-and-forth with the tool
  results and such, somehow, through a model not exactly made for agentic tasks.
- Somehow we have to do all this without overwhelming the model, probably via
  seperation of concerns + delegation of tasks via subagents or passing down
  work so that the system prompt is seperated into what task matters only. It
  kills caching but I could maybe subagents an opt-out instead? Just so that you
  can insert Deepseek V4 API and its prefix caching easily and immediately have
  better token efficiency, just because this agentic package is meant to be a
  standalone package thats made mainly for the app we are building, but also a
  standalone package on pub.dev for being another option for agentic frameworks
- Basically, small model + agentic/tooling loop + normal responses with ability
  to spawn UI via <interface> tags

I just cant imagine how to build this package, because the package is basically
just going to be a wrapper to the small model and then its done, so we need to
somehow package but Gen UI (optionally) and also tooling and the needed looping
for it, with native default support for subagents or subtasking or delegation
(that can be opt out of) just to reduce the load from the poor small model

What do you think of this project?

Here is my issue, I have an idea of the steps or the flow of everything, but I
cant imagine how to architecture it or do it in the context of an entire
conversation level

That is unless maybe I scope it to just a single message? Where:

History + User message in, the framework just sends that to the model AND THAT
ONLY HANDLES THAT ONE TURN WITH THE USER (different from tool calls which are
technically user turns but semantically are tool results), then the output is
the model's message as a stream, or another endpoint where its the direct widget
now. Is that clean scoping?

I dont see a reason for the package to be holding into its own internal memory
the history except for the part where it calls the model where we include the
provided history that came from the dev calling the framework itself, but it
also somehow has to automatically save that message into the conversation
history I think for a clean DX? Honestly I do not know anymore.

A clean and easy approach for me that doesnt exactly have downsides except DX is
that we only take a prompt (history + user message) as input as well as the
registered tools and UI definitions from the dev, and the package just outputs
the widget and/or the raw stream/future of the final response in the model
("final" because I am imagining that inside, on delegation or subagent mode we
would be creating new chat histories with different prompts without using the
existing user history meaning we technically have multiple responses internally,
but on the cache-friendly mode yeah we probably just have a chain of back and
forth between tools and model internally but idk if supporting it would make
things extra harder or complicated)

Anyway, that approach is simple. History + registries in, response out.

But the other approach, one with simpler DX and a better looking quickstart, is
where the dev can just call the package, run .startChat(List<Message> history),
then from the returned object just do .sendMessage and all that and EVERYTHING
is handled to them by default, including appending or updating the history, plus
an option to even persist it maybe.

But I guess this could easily be done by first doing the top approach first for
cleanliness in the system, then creating a helper or wrapper in the main package
that makes the second approach possible and easy. What do you think?

Dev Friend: This is a genuinely interesting package concept, and you're closer
to the right architecture than you think. Let me untangle it.

---

## The Fundamental Insight: Two Separate State Machines

You're conflating two things that need to be completely separate:

**External state** — the conversation history between the user and the app. The
dev owns this.

**Internal state** — the tool-call loop happening within a single turn. The
package owns this invisibly.

Once you split these, everything becomes clean. The package's agentic loop is an
_implementation detail_, not a public API concern. The dev never sees tool call
turns. They send a message, they get a response. Whatever happened in between —
five tool calls, a subagent delegation, a UI spawn — is opaque.

---

## The Layered Architecture

```
┌─────────────────────────────────────────────┐
│  AgentChat  (stateful wrapper, optional)    │  ← Layer 3
│  .startChat() .sendMessage() .history       │
└──────────────────┬──────────────────────────┘
                   │ wraps
┌──────────────────▼──────────────────────────┐
│  AgentSession.respond(                      │  ← Layer 2
│    history, message, registries             │
│  ) → AgentResponse                         │
└──────────────────┬──────────────────────────┘
                   │ runs internally
┌──────────────────▼──────────────────────────┐
│  AgentCore (the loop engine)               │  ← Layer 1
│  - tool dispatch                           │
│  - subagent delegation                     │
│  - output parsing                          │
└─────────────────────────────────────────────┘
```

Layer 1 is the hard part. Layer 2 is the clean public API. Layer 3 is the DX
sugar. Ship in that order.

---

## How to Not Destroy a Small Model

The real architectural challenge is context budget. Qwen 0.8B doesn't have the
reasoning capacity to juggle 20 tool schemas + full history + a complex system
prompt. The fix is **contextual pruning at call time**, not at registration
time.

```
ToolRegistry.resolve(userMessage) → List<Tool>
```

This method returns only the 2–3 tools relevant to this specific message. Could
be keyword matching, could be a cheap embedding cosine check, could even be a
fast regex — doesn't matter. The point is the model _never sees tools it doesn't
need_. This single mechanism is probably 80% of what makes small models viable
here.

Same idea for the system prompt: you define it in sections, and the framework
only injects sections relevant to the current context. A `<ui_spawning>` section
only goes in if the UI registry is non-empty and the message seems UI-relevant.

---

## The Internal Loop (invisible to the dev)

```
buildContext(history, message, resolvedTools)
  → call model
  → parse output:
      if toolCall     → execute, append result, loop (max N iterations)
      if <interface>  → extract, continue parsing remaining text
      if delegate     → spin up SubagentContext, run, fold result back in
      if text         → done, emit
  → return AgentResponse { stream, widgets }
```

The loop has a hard iteration cap (configurable, default maybe 6). After that it
forces a text response. Small models will sometimes spiral — you need this guard
unconditionally.

---

## Subagents vs. Cache Mode

Your instinct is right: make this a config flag.

```dart
AgentConfig(
  delegationMode: DelegationMode.subagent,  // fresh context, no caching
  // or
  delegationMode: DelegationMode.inline,    // chains in same history, cache-friendly
)
```

`subagent` mode: when the model decides it needs to "delegate" (you define this
as a special tool — `delegate_task(prompt, context)` — the framework spins up a
new `AgentCore` instance with a stripped system prompt scoped to just that
subtask. The result folds back into the parent as a synthetic tool result. Clean
separation, model only sees what matters, but you lose prefix caching.

`inline` mode: everything stays in one conversation thread. Prefix caching works
because the system prompt + earlier history is stable. The tradeoff is the model
accumulates context load. This is where DeepSeek V4 with prefix caching actually
shines — the cheap cached tokens mean the longer chain doesn't cost much.

For Qwen 0.8B, `subagent` is probably the better default. For anyone dropping in
a larger model with prefix caching, they flip to `inline`.

---

## API Design: Your Instinct is Correct

Do the stateless layer first:

```dart
final response = await AgentSession(config).respond(
  history: messages,
  message: userMessage,
  tools: toolRegistry,
  ui: uiRegistry,
);
```

Then wrap it:

```dart
final chat = AgentChat.start(
  config: config,
  tools: toolRegistry,
  ui: uiRegistry,
  initialHistory: [],
);

final response = await chat.send("Hello");
// history is managed internally, optionally persisted
```

The `AgentChat` wrapper is maybe 80 lines on top of the stateless core. It just
holds a `List<Message>` and calls `respond()` with it every time. Persistence is
an optional `HistoryStore` interface you pass in — the dev can plug in SQLite,
Hive, whatever. Default is in-memory.

---

## The `<interface>` Tag Handling

Since you already have this handled on the rendering side, the package just
needs to:

1. Stream text output normally
2. When an `<interface>` tag is encountered mid-stream, emit a `WidgetEvent` on
   a parallel sink
3. Continue streaming the surrounding text

So `AgentResponse` has two channels:

```dart
class AgentResponse {
  final Stream<String> textStream;
  final Stream<InterfaceEvent> widgetStream;
}
```

The dev subscribes to whichever they care about. If they only care about text,
the widget stream just drains silently.

---

## What You Actually Need to Build (in order)

1. `OutputParser` — handles tool call format, `<interface>` tags, plain text,
   delegate signals
2. `AgentCore` — the loop with the iteration guard and tool dispatch
3. `ToolRegistry` + `resolve()` — the context pruning mechanism
4. `AgentSession.respond()` — assembles context, runs core, returns
   `AgentResponse`
5. `AgentChat` — stateful wrapper, history management, optional persistence
6. `SubagentContext` — stripped-down `AgentCore` invocation for delegation mode

The `<interface>` rendering and the actual LLM HTTP client are yours to plug in
— the package takes a `ModelClient` interface.

---

The package is more than just a wrapper because the _value_ is in layers 1 and
2: the context pruning, the loop guard, the subagent/inline mode split, and the
clean output parsing that makes small models actually usable agentically. That's
the real product.
