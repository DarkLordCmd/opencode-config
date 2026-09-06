---
name: redesign
description: >
  Use this skill only when the user explicitly asks to redesign code, such as "redesign this
  code", "redesign this module", or invokes $redesign. Do not trigger for ordinary code
  review, refactoring, cleanup, naming, documentation, or comment-writing requests unless the
  user specifically asks for a redesign.
---

# Redesign Code

Redesign code to reduce complexity while preserving externally visible behavior. Treat working
code as the starting point, not the finish line.

## Workflow

1. Establish the behavioral contract: tests, public APIs, data formats, side effects, error
   semantics, and caller expectations.
2. Identify the main complexity symptom: change amplification, cognitive load, or unknown
   unknowns. Prefer redesigns that directly reduce that symptom.
3. Sketch at least two viable designs for non-trivial changes. Compare interface simplicity,
   generality, consistency with the codebase, implementation effort, and migration risk.
4. Implement the smallest redesign that materially improves the design. Keep unrelated
   cleanup out of scope.
5. Verify behavior with the narrowest reliable tests, then broaden verification when public
   contracts or shared modules changed.

## Design Moves

### Make Modules Deeper

Prefer modules with simple interfaces and substantial hidden implementation. Optimize the
common call path first; rare cases can take more explicit options.

Watch for shallow wrappers, pass-through methods, and APIs where callers must understand most
of the implementation to use them correctly. Merge or remove layers that do not provide a
different abstraction.

### Hide Information

Keep design decisions in one place: data representation, parsing rules, ordering constraints,
retry policy, caching, validation, and low-level protocols. If the same decision appears in
multiple modules, move it behind a single interface.

Avoid temporal decomposition when it causes every step to share the same internal knowledge.
Split by responsibility and hidden information, not by execution order.

### Pull Complexity Downward

When complexity is unavoidable, absorb it inside the module with the best context instead of
forcing every caller to handle it. Remove configuration knobs, flags, callbacks, and special
cases unless callers genuinely need control.

Make the default path obvious and hard to misuse.

### Separate General and Special Purpose Code

Design interfaces general enough for the current family of uses, but keep the implementation
limited to what is needed now. Keep special-case policy at the edge or behind a small adapter
instead of mixing it into reusable core logic.

### Redesign Error Semantics

Reduce exception and error-handling surface area when the operation can be defined to succeed.
For example, make idempotent cleanup guarantee the postcondition rather than require callers to
check whether cleanup is needed first.

Do not hide real failures that callers must know about. Centralize unavoidable error handling
where possible.

### Improve Names and Consistency

Use precise, consistent names that match the abstraction after redesign. If a concept is hard
to name, treat that as a design signal: the responsibilities may still be mixed.

Follow existing local patterns unless replacing them everywhere touched is clearly worth the
cost.

## Red Flags

Use these as redesign triggers:

- Change amplification: a small behavior change requires edits in many places.
- Cognitive load: callers or maintainers must remember hidden rules to make safe changes.
- Unknown unknowns: it is unclear where a change should be made or what it might affect.
- Information leakage: the same design decision is duplicated across modules.
- Pass-through layer: a method or class mostly forwards to another with the same abstraction.
- Overexposed interface: common callers must supply options needed only by rare cases.
- Special-general mixture: reusable logic and one-off policy are intertwined.
- Conjoined methods: one method cannot be understood or changed without another.
- Vague names: names like `data`, `info`, `manager`, or `helper` hide the actual concept.

## Output Standard

When presenting a redesign, state:

1. The complexity problem being reduced.
2. The selected design and the main alternative rejected.
3. The behavior-preservation strategy.
4. The verification performed or still needed.
