---
layout: post.liquid
title: "The Guide Conversion That Became a Language Audit"
description: "We set out to port our JS guides to lykn. We found three bugs in the language instead."
published_date: 2026-04-15 00:00:00 +0000
is_draft: false
---

We came into this with a clear, bounded goal: port our [JavaScript coding guides](/posts/building-the-safety-net.html) to lykn syntax. We had 18 JS guide files. We had a prompt template for Claude Code. We estimated it would be mostly mechanical -- translate syntax, update cross-references, mark JS anti-patterns that lykn eliminates as "ELIMINATED BY LANGUAGE DESIGN."

We were wrong about the "mostly mechanical" part.

## The Guide 00 Bombshell

The first deliverable was Guide 00 -- the surface forms reference. We told CC to verify every single form against the actual compiler output, not trust the design documents. We'd learned that DDs describe the *design* and the compiler is the *truth*, and these sometimes diverge.

That decision cracked everything open.

CC came back with Guide 00 and it was excellent. But the Known Gaps section at the bottom was a gut punch. Three findings that changed the trajectory of the entire project:

**Finding 1: `=` is assignment, not equality.** The design document had specified that `(= a b)` would compile to `a === b` -- strict equality, matching every Lisp dialect. The Hazard Landscape research had specifically recommended this. But the implementation had gone a different way. `(= x 1)` compiled to `x = 1`. Every Lisp programmer who wrote `(= a b)` expecting a comparison would silently get an assignment.

**Finding 2: `and`/`or`/`not` compiled as function calls.** The README listed these as logical operators. They weren't. `(and x y)` compiled to `and(x, y)` -- a call to an undefined function. Every developer from any Lisp background would reach for `and`/`or`/`not` and get runtime errors.

**Finding 3: `bind` type annotations were documentation-only.** `(bind :number x (compute))` compiled to `const x = compute();` -- the `:number` annotation was silently discarded. Meanwhile, `func` type annotations generated full runtime checks. If you annotated a type on `bind`, you expected it to be enforced. It wasn't.

## "Why Do We Need Assignment At All?"

Duncan's first reaction to Finding 1 was exactly right: "Why do we need `(= ...)` for assignment? We have `bind`."

Once you ask that question, the answer is obvious. In surface lykn, every path to assignment is already covered by a named form: `bind` for initial binding, `reset!` for cell replacement, `swap!` for cell update, `assoc`/`dissoc`/`conj` for immutable data updates. There is zero surface-language need for a raw assignment operator. The kernel needs it (for compiled output of `reset!`, class constructors, `for` loop counters), but those are all compiler internals.

The same logic extended to logical operators. Surface lykn uses English-word forms everywhere -- `bind` not `const`, `func` not `function`, `match` not `switch`. `and`/`or`/`not` are the natural surface-level names. The fact that they fell through to function calls was clearly a bug, not a design choice.

We wrote DD-22. Five surface operator interceptions:

```lisp
(= a b)    ;; compiles to: a === b
(!= a b)   ;; compiles to: a !== b
(and a b)  ;; compiles to: a && b
(or a b)   ;; compiles to: a || b
(not x)    ;; compiles to: !x
```

Then we had to update everything we'd already written. We'd created workaround documentation for the bug ("WARNING: `=` is assignment, NOT equality! Use `===`!"), and now that the bug was fixed, those workarounds were themselves wrong. Three versions of the supporting documents: the original, the workaround, the fix. A good lesson in why you fix bugs instead of documenting them.

## The Cascade

DD-22 exposed the next problem immediately. The README's browser example:

```lisp
(set! el:text-content "Hello from lykn!")
```

Wait -- `set!` didn't exist yet. The original example used `=` for DOM property assignment. After DD-22, that compiled to a comparison. The browser example was silently broken.

Duncan raised the incisive question: surface lykn has `bind` for new bindings, `reset!`/`swap!` for cells, `assoc`/`dissoc`/`conj` for immutable updates. But DOM property assignment isn't any of those. There was a genuine gap in the mutation model.

We designed `set!` (DD-23) -- a new surface form for property mutation on external objects. Colon syntax required (can't be used for bare variable reassignment). Compile error on cells (use `reset!`). Compile error on bare bindings (use `bind`).

The complete mutation model after DD-23:

| What you're mutating | Form | Convention |
| --- | --- | --- |
| New binding | `bind` | No `!` -- not mutation |
| Cell value | `reset!` / `swap!` | `!` marks mutation |
| Own data (new copy) | `assoc`/`dissoc`/`conj` | No `!` -- new value |
| External property | `set!` | `!` marks mutation |

Every mutation form has `!`. Every non-mutation form doesn't. The convention holds perfectly.

## Bind Enforcement

The third discovery -- `bind` type annotations being documentation-only -- was fixed in DD-24 with three tiers:

**Compile-time**: `(bind :number x "hello")` is a compile error. The compiler can see the mismatch statically.

**Runtime**: `(bind :number x (compute))` emits a `typeof` check after the declaration. Same pattern as `func`. Stripped by `--strip-assertions`.

**Lint-time**: `(bind x (compute))` with no annotation triggers a linter warning. `:any` suppresses it.

The elegant part: type-compatible literals skip the runtime check entirely. `(bind :number MAX-RETRIES 3)` compiles to `const MAX_RETRIES = 3;` with no check -- the compiler can see that `3` is a number. No clutter, no runtime cost, but the annotation is still verified.

## What We Learned

**Verification against the compiler is non-negotiable.** The decision to have CC compile-check every example is what surfaced the operator bug. If we'd just translated the design document into guide prose, we'd have shipped documentation that contradicted the compiler.

**Language design decisions compound.** DD-22 (operators) exposed DD-23 (`set!` gap) which clarified DD-24 (`bind` enforcement). Each fix revealed the next issue. But they all fit together -- the mutation model is now cleaner than it was before we started. The cascade wasn't scope creep; it was the language telling us what it needed.

**The guide conversion was the audit.** We thought we were writing documentation. We were actually stress-testing the language design against real code patterns. Every guide entry that said "here's how you do X in lykn" was an implicit test: does lykn actually have a clean way to do X? When it didn't, we found out immediately. The guides became a forcing function for language completeness -- they surfaced gaps that unit tests and example programs hadn't caught because those operate within the language's comfort zone, while guides must cover the full surface area.

---

*What started as "port the JS guides" produced 19 guides, 3 decision documents, 5 new operators, 1 new form, 1 enforcement upgrade, and 1 compiler bug fix. The tally for a "mostly mechanical" task.*
