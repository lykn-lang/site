---
layout: post.liquid
title: "Heads-Down on 0.6.0 — A Progress Update"
description: "A quiet stretch of heavy lifting: compiler coherence, a byte-exact refactoring tool, a much smaller surface compiler, and a few honest lessons. Next stop: a release candidate."
published_date: 2026-06-30 21:40:00 +0000
is_draft: false
---


Hey all — wanted to give a quick update on what we've been up to since the last post. It's been a stretch of real heavy lifting, and a lot of learning, but also very heads-down and quiet: the kind of work that doesn't make for splashy announcements while it's happening. We're diving back in right after this, and the next time you hear from us it should be to invite you to try out a **0.6.0 release candidate**.

Here's the shape of what got done, and — because it's the more interesting part — some of what we learned along the way.

## What 0.6.0 is

0.5.x was about docs, scaffolding, and getting the story straight. **0.6.0 is the release where the toolchain catches up to the language's own claims.** Concretely, that's meant landing the kernel/surface compiler split, finishing the JS-side compiler architecture, generating TypeScript `.d.ts` files from `:type` annotations, and adding ICU-based internationalization to the `template` macro — then tightening everything down before we cut a release.

Most of that is now done. A few highlights.

## Two compilers, one language — and proof they agree

lykn has two compiler implementations: a Rust one and a JavaScript one. They share the surface language but had drifted apart at the edges. A big chunk of this cycle went into making *"same input, same output"* true by construction — and, crucially, into a cross-compiler test harness (`compile-both`) that compiles a program through **both** backends and fails if they disagree.

The corpus now runs **1,345 assertions with zero semantic divergences**. Where output differed, it was cosmetic (a stray semicolon after an `async` declaration, an internal gensym counter) and got fixed at the source. That harness is the thing that lets us make coherence claims and actually back them up.

## A tool that moves code without touching it

This one's my favorite, because it closes a loop that goes all the way back to why we work the way we do.

The JS surface compiler had accumulated one enormous file — `surface.js`, north of 2,300 lines — that needed to be broken apart: helpers and form-emitters lifted out into their own modules. The obvious way to do that is to move a function and adjust it as you go. The problem is that "adjust it as you go" is exactly how, a couple of releases back, a function got quietly *reimplemented* instead of moved, and shipped a subtle bug.

So instead of moving code by hand, we built a small tool that **parses only to locate a function, then copies its raw bytes** — never regenerating, never reflowing, never "improving" it in transit. The moved code is provably identical to the original, and the tool refuses to proceed if a verification step fails.

Then we pointed it at `surface.js` and let it work:

- **~20 functions, roughly 1,900 lines, relocated byte-for-byte** — including the exact function that got reimplemented-and-broken the first time around. This time it moved without a character changing.
- `surface.js` went from **2,315 lines down to 448** — now just its irreducible core.
- The full suite stayed green at every step.

There's a nice principle buried in there: when a mechanical job hits a wall, invest in the tool rather than hand-editing the risky file. At one point the tool hit an import collision on the highest-stakes module; rather than reach in and edit it by hand, we taught the tool a new trick (and wrote tests for it first). It came out the other side permanently more capable.

## The template macro speaks ICU now

`template` grew real internationalization support — ICU MessageFormat, with plural/select/number/date arguments — mirrored across both compilers, with a runnable i18n guide and cross-compiler equivalence tests. If you've wanted lykn to handle "1 file" vs "2 files" without hand-rolling it, that's landing in 0.6.0.

## Some lessons from this cycle

The engineering above is the visible part. The part that actually made us better is the pile of things that went sideways and what we changed because of them. A few worth sharing:

**"Closed" is not "merged."** We track work carefully, and a lot of it was marked done in our notes. When we went to reconcile everything onto the release branch, a branch-by-branch audit turned up **two large bodies of finished work that had never been merged** — sitting on feature branches for weeks. Everything compiled and passed tests, which is exactly what hid it: the language worked fine via the older code path; only the newer *architecture* was missing. The lesson was blunt and now automatic: before you call something landed, check that its commits are actually reachable from the release branch. A green test run can lie to you about this.

**The compiler was politer than we thought.** Our docs (and our own philosophy page) say things like "lykn prevents `var`" and "there's no `this` in surface code." Turns out the enforcement that makes those statements *true* had only ever been wired into the test runner — normal compilation happily let bare kernel forms slip through. The design intent was right; it just wasn't actually enforced. So "the language claims X" and "the compiler guarantees X" are different sentences, and the next thing we're doing is closing that gap: making the surface language genuinely refuse the forms it's always said it refuses (with a clean `kernel:` escape hatch for when you really mean it).

**Rebuild first, trust nothing.** More than once, a test run was quietly comparing against a stale compiled artifact — producing phantom failures *and* phantom passes. Now the tooling rebuilds first and fails loudly if it detects a stale binary or build directory. Freshness is not something to assume.

**Stopping is a feature.** Some of the best moments this cycle were when a task got *paused* because a spec didn't survive contact with the actual compiler — better to surface the inconsistency and re-scope than to charge ahead and migrate a hundred files against a wrong assumption. Verifying an assumption against ground truth beats verifying it against your own confidence.

None of these were disasters. But writing them down — what happened, why, and what changed — is turning out to be at least as valuable as the code itself. It's how the workflow keeps getting sharper.

## What's left

Not much, and it's well-scoped:

- **Finish enforcing the closed surface namespace** (the "politer than we thought" item above).
- **A source-level linter** — `lykn lint` — for idiom and style, building on the anti-patterns catalog.
- **A docs pass** to reconcile the guides with everything that shipped.
- Then version bumps, release notes, and the release itself.

So: heads-down for a little longer, and then a **release candidate** you can actually kick the tires on. Thanks for your patience through the quiet stretch — the next update should come with something to download.
