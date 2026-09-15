# Text Editor Design Principles

Guidelines for designing text editor behavior. Derived from *The Craft of Text
Editing* by Craig A. Finseth. These are design axioms; prioritize accordingly.

## Core axioms (highest priority)

When in doubt, ask: "Does this follow the core editing contract?"

1. **Responsiveness** — Every user action must produce an *immediate, visible*
   effect: cursor motion, text change, message, or bell. The user should never
   wonder whether their input was received. No silent state changes.

2. **Simplicity** — *"Keep simple things simple."* The basic operations
   (insert, delete, move) must be conceptually trivial. Do not multiply modes
   or steps for common cases. Inserting a character = typing a character.
   Period.

3. **Consistency** — The same input/keystroke must produce the same result
   across the entire editor. No context-sensitive surprises.

4. **Progress** — Every command must advance the user toward their goal.
   Eliminate commands that do nothing but consume effort (e.g. "show line
   number" when it doesn't enable editing).

5. **Permissiveness** — The user is in control, not the tool. Allow any
   request at any time. Do not force users through a rigid step-by-step flow
   where they must abandon work to backtrack.

6. **Uniformity** — Knowing one part of the command set should let the user
   *predict* the rest. Commands fit an orthogonal, regular pattern.

7. **Extensibility** — Design with "holes" for user additions. The architecture
   must accommodate new commands and workflows without breaking the
   underlying model.

## Error-handling directives

- Validate user input as soon as it is logically possible after entry.
- Give immediate confirmation when input is valid.
- Display a clear error indicator when input fails; reject incorrect input
  rather than silently accepting it (unless infeasible).
- For incremental input (e.g. a number), validate individual characters
  during entry; validate the whole value only when the user signals
  completion.

## Mode design (if modes are unavoidable)

Modes are sometimes justified for *structural* operations, but they are a
source of friction. Follow these rules:

- **Minimize**: Avoid modes wherever possible. If a mode can be removed
  without breaking core functionality, remove it.
- **Visibility**: If a mode exists, it must have an explicit, always-visible
  indicator. Never hide mode state.
- **Activity alignment**: Mode changes should align with activity boundaries
  — i.e. when the user shifts tasks, not arbitrarily mid-operation.
- **State transparency**: Show all relevant state on screen so a knowledgeable
  user can predict the next command's effect from the current display alone.

> ❗ Finseth considers insert/edit (input-overtype) modes an example of
> making a simple thing complicated. Default to direct insertion unless
> there is a strong, mode-specific reason.

## Editing-model directives

- Treat the file as a uniform data model. Do not impose arbitrary upper
  limits on file size, line length, or buffer count.
- Support both insertion and replacement editing where applicable, but
  never let a mode accidentally clobber a line break or structural element.
- Basic editing should work byte/char/line-wise consistently; structural
  units (words, paragraphs, sentences) are commands layered on top, never
  replacements for the base model.

## Command-set design

- **Composition**: Complex operations must be expressible as combinations of
  simple, well-defined commands — not as monolithic, hard-to-predict features.
- **Orthogonality**: Each command does one thing. Avoid aliases that differ by
  subtle side-effects (e.g. two delete commands with minor semantic drift).
  If two commands feel identical, merge them.
- **Discoverability aid**: Commands that are not self-evident need inline
  affordances (documentation, completion hints, preview). Prefer showing the
  effect *before* commitment where the operation is destructive.
- **Progress check**: Before adding a command, verify it serves a real editing
  goal. If it only reflects internal state without enabling change, reconsider.

## Redisplay / rendering directives

- **Coherence**: Screen updates must stay coherent with the buffer state.
  Partial or stale renders violate responsiveness.
- **Efficiency through caching**: Minimize data copies between model and view.
  Caches are acceptable; they must be invalidated correctly on any buffer
  change.
- **Atomicity of updates**: A logical command's display effects should appear
  as one coherent change, not a flicker of intermediate states.

## Undo / transaction model

- Treat changes as **atomic transactions**: a single undoable unit is one
  coherent user intent.
- Undo should be able to reverse an arbitrary sequence of prior changes
  (not just the immediately preceding one).
- Undo-of-undo should be straightforward to re-apply.

## File-handling directives

- Reading and writing files must be fast and reliable.
- Adding a new file to the session must be painless.
- Store files on disk (or an equivalent durable backing) — do not rely on an
  OS feature you cannot control for correctness.

## Extensibility directives

- Provide well-defined hooks for binding events/keys to built-in or
  user-defined functions.
- Prefer external helper commands/processes over embedding a heavy scripting
  engine. Let users compose the editor with the broader toolchain.
- Maintain **backwards compatibility** for extension APIs. Breaking changes
  are a feature regression.

## Documentation directives (for the agent)

If you add or modify a feature:

1. Document it *at the same time* — undocumented features are non-features.
2. Documentation must include at least one concrete example.
3. Keep documentation precise and concise; optimize for finding, not for
   literary completeness.

## Checklist before shipping a new behavior

- [ ] Is every effect immediately visible (responsiveness)?
- [ ] Does the simplest case stay simple (simplicity)?
- [ ] Would the same keystroke behave identically elsewhere (consistency)?
- [ ] Does the user genuinely need this, or is it busywork (progress)?
- [ ] Can the user override or abandon this freely (permissiveness)?
- [ ] Can the user predict this from commands they already know
      (uniformity)?
- [ ] Can this be extended or recombined later (extensibility)?
- [ ] If it uses a mode — is the mode visible and necessary (mode rules)?
- [ ] Is input validated promptly with clear success/error feedback?
- [ ] Is the feature documented with an example?

---

*Source: Finseth, C. A. — "The Craft of Text Editing" (1991),
Chapter 9: Command Set Design. Available in full at
https://finseth.com/craft/*
