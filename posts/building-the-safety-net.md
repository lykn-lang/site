---
layout: post.liquid
title: "Building the Safety Net"
description: "How 1,569 concept cards and 7 authoritative sources became the foundation for writing JavaScript without TypeScript."
published_date: 2026-03-27 00:00:00 +0000
is_draft: false
---

## The Problem That Started It All

It began with a file listing. Duncan dropped a text file into the conversation -- just a directory tree of the `ai-rust` repo -- and said, essentially: "This is what keeps our Rust code quality sky-high. We're about to write a *ton* of JS. We need something like this."

The `ai-rust` repo was the secret weapon. A `SKILL.md` entry point that Claude Code reads on bootstrap, backed by 13 topical guides plus two multi-part deep-dives (CLI tools and Cargo), all grounded in curated reference PDFs. The guides weren't opinions -- they were distilled from authoritative sources, processed into concept cards, and synthesized into actionable patterns with numbered IDs, strength levels (MUST/SHOULD/CONSIDER), good/bad code examples, and cross-references. It was the reason CC produced Rust code that looked like a senior engineer wrote it.

And now we were staring down a mountain of JavaScript work for lykn -- the s-expression syntax for JS that Duncan had been designing -- and JavaScript didn't have a compiler that would save you from yourself the way `rustc` does. No borrow checker. No exhaustive pattern matching. No type system unless you opted into TypeScript (which we explicitly were not doing). Just `undefined`, implicit coercion, and hope.

The first thing Duncan said was: "We're going to be using absolutely NO NODE.JS!!!" -- in all caps, with three exclamation marks. The constraints were clear from the start: Deno as the runtime, Biome for linting and formatting, zero npm in the dev workflow. This wasn't going to be a typical JS project.

## Designing the Guide Structure

The shape of `ai-rust` was the obvious starting template, but JavaScript is a fundamentally different beast. Rust has the compiler enforcing half your discipline for you. With JS, the guides themselves and the tooling config have to carry more of that weight. That observation -- that the guides matter *more* for JS than for Rust, not less -- set the tone for everything that followed.

Claude proposed an initial outline of 14 guides, and we talked through the mapping from Rust concepts to JS equivalents. "Ownership and borrowing" became "Values & References" -- JS doesn't have Rust's ownership model, but it has its own mutation/reference discipline that's equally important to get right. "Traits" split into "Functions & Closures" since that's the JS composition primitive. A "No-Node Boundary" guide was added because that constraint was unique to this project, and without it CC would instinctively reach for Node patterns.

Duncan chose "ai-js" as the repo name and said: let's start with the guide outline, not the first guide. Get the architecture right before building.

## The Reference Library Breakthrough

Then came the moment that elevated the whole effort. Claude recommended a curated list of books -- top-tier JS references that would serve as the authoritative foundation, the same way the Rust repo had been grounded in reference PDFs:

- **Exploring JavaScript (ES2025)** by Axel Rauschmayer -- the most current, spec-grounded treatment
- **Deep JavaScript** by Rauschmayer -- the "why does JS do that?" companion
- **JavaScript: The Definitive Guide, 7th Edition** by David Flanagan -- the encyclopedic reference
- **Eloquent JavaScript, 4th Edition** by Marijn Haverbeke -- pedagogical, excellent for examples

Duncan's response was immediate and enthusiastic. He already knew this was the move that had made `ai-rust` so strong. And then he dropped the bombshell: "guess what I've got? Check out ccs.txt!"

He'd already done the work.

1,569 concept cards. Seven sources. Already processed, already organized:

| Source | Cards |
| --- | --- |
| Exploring JavaScript (ES2025) | 476 |
| JavaScript: The Definitive Guide | 341 |
| Eloquent JavaScript | 330 |
| Deep JavaScript | 248 |
| Deno documentation | 65 |
| ESLint documentation | 62 |
| Biome documentation | 54 |

All four books Claude had recommended, plus both tooling doc sets, plus ESLint as a bonus (useful for the ESTree and AST concept cards that would feed directly into lykn's compiler work). Duncan had been working in parallel, processing the books while the guide structure was being designed.

This was the foundation. The guides wouldn't be built from general knowledge or training data -- they'd be distilled from 1,569 authoritative reference cards, with a clear source priority hierarchy.

## The Source Priority Decision

An important design decision came up during the prompt-writing process: what happens when different sources disagree? Duncan established a clear priority ordering:

1. **Exploring JavaScript** -- MOST authoritative (ES2025, spec-grounded)
2. **Deep JavaScript** -- for spec-level "why" explanations
3. **JavaScript: The Definitive Guide** -- encyclopedic but some pre-ES2020 patterns
4. **Eloquent JavaScript** -- LEAST authoritative for API guidance (pedagogical, less precise on edge cases)

This wasn't arbitrary. Rauschmayer's books are the most current and most rigorously tied to the ECMAScript specification. Flanagan is comprehensive but the 7th edition reflects 2020-era patterns. Haverbeke is excellent for learning but optimizes for clarity over precision. Having this hierarchy meant CC would know which source to follow when they presented different approaches.

## Building the First Guide

The first guide was Guide 01: Core Idioms. But here's the thing -- Claude couldn't write it directly. The concept cards existed in Duncan's `ai-js` repo, not in the conversation. Claude had the file listing but not the file contents. The actual card content -- the specific claims, examples, edge cases, and rationale from each source -- was only accessible to Claude Code.

So the approach shifted: instead of writing the guide, Claude would write a *prompt for Claude Code* that told CC exactly which concept cards to read, what structure to follow, and what idioms to cover.

This prompt was detailed. It listed ~130 specific concept card filenames organized by topic (declarations and scoping, equality and comparison, destructuring, template literals, naming conventions, modules, functions, values and types, Deno-specific, Biome-specific). It proposed 20 idioms as a starting outline but told CC to adjust based on what the cards actually said. It included the Rust guide as a structural template. And it had hard guardrails: no Node.js, no frameworks, no TypeScript, and critically -- "Don't make claims the cards don't support."

CC produced Guide 01 with 24 idioms. Claude reviewed it and found it strong -- the concept card grounding was evident in citations like "Deep JS Ch. 7-8" and "Exploring JS Ch. 27." The `==` coercion trap table, the named parameters pattern with the `= {}` outer default, the `this` context table -- these were all details that came from actually reading the cards, not from pattern-matching on general JS knowledge.

But there were issues. One "Good" example used `import { readFile } from "node:fs/promises"` -- a Node.js import in a Deno-first guide. And the Related Guidelines section referenced guide numbers that didn't exist because CC hadn't been given the full guide list.

## The Corrections Loop

This established a pattern that would repeat for every guide: generate, review, correct. Claude wrote a targeted corrections prompt that included the full guide list (so CC could fix cross-references) and specific edits for the Node.js import and two missing idioms (`for-of` over `.forEach()` and early returns). The corrections prompt was surgical -- "edit in place, don't rewrite the entire file."

Duncan also caught something the original prompt had missed: CC needed the full guide list in every prompt, not just the first one. Without it, cross-references would be wrong every time. This became a standard block that was copy-pasted into every subsequent prompt.

## The Assembly Line

With the pattern established, the remaining guides came together quickly over two sessions. Each guide followed the same process:

1. **Claude designs the prompt** -- identifies which concept cards CC needs to read, proposes an idiom list, sets guardrails
2. **Duncan runs it through CC** -- CC reads the cards and produces the guide
3. **Claude reviews the output** -- checks for accuracy, Node.js leaks, cross-reference correctness, source citation quality, and overlap with other guides
4. **Corrections prompt if needed** -- targeted fixes, never full rewrites

The guides built on each other:

- **Guide 02 (API Design)** drew from function signatures, module interfaces, class/factory patterns, iteration protocols, and proxy-based patterns. The secret-token pattern for async factories (from Deep JS) was a highlight.

- **Guide 03 (Error Handling)** had the heaviest concept card load -- about 100 cards covering sync exceptions, Promise rejections, async/await error flows, custom errors, and validation. The `return await` inside `try` idiom, the fire-and-forget async bug, and the `.catch()` placement trap were all idioms that would prevent real production bugs. Claude called it the strongest guide of the batch.

- **Guide 04 (Values & References)** was the Deep JS guide. Nearly half its ~130 concept cards came from Rauschmayer's deep-dive book. The "pass by identity, not by reference" terminology (with the `swap()` proof), the `Object.assign()` vs spread `__proto__` edge case, the definition-vs-assignment distinction, and the non-destructive array methods from ES2023 -- this was the guide that made you *think* about mutation the way Rust forces you to.

- **Guide 05 (Type Discipline)** was the guide that had to stand on its own feet. The instinct with AI-generated code is always "just use TypeScript," and this guide's job was to make plain JS with JSDoc a confident, legitimate choice. The discriminated unions pattern with `kind` properties mapped directly to lykn's AST node dispatching.

- **Guide 06 (Functions & Closures)** was the biggest concept card list at ~150 cards. Closures, scope mechanics, `this` binding rules, higher-order functions, partial application, generators, and pure functions. The Deep JS environment/scope cards provided the spec-level explanation of how closures actually work -- not the hand-wavy "captures variables" version, but the real environment-record machinery.

- **Guide 07 (Async & Concurrency)** covered the event loop, Promise mechanics, async/await patterns, async iteration, cancellation with AbortController, and concurrency limiting.

## What Made It Work

Looking back, several things made this process unusually effective:

**The concept cards were the foundation, not general knowledge.** Every idiom had to cite specific behavior from the cards. This prevented the guides from drifting into opinions or blog-post-level advice.

**The source priority hierarchy resolved conflicts.** When Flanagan and Rauschmayer disagreed on a pattern, the hierarchy was clear. This prevented CC from averaging between sources or picking whichever sounded most confident.

**The Rust guide was a structural template, not a content template.** The format (numbered IDs, strength levels, good/bad examples, rationale, cross-references, summary table) transferred perfectly. The content was entirely JS-native.

**The "what NOT to do" sections in each prompt were as important as the "what to do" sections.** "Don't include Node.js patterns" prevented the most common CC failure mode. "Don't recommend switching to TypeScript" kept the Type Discipline guide confident instead of apologetic.

**The review-and-correct loop caught real issues.** The Node.js import in Guide 01, the duplicate idioms in Guide 02, the cross-reference errors everywhere before the guide list was included -- these were all caught in review and fixed with targeted correction prompts.

## The Numbers

By the end of two evenings' work:

- **7 guides** written, reviewed, and corrected
- **~200 idioms** across all guides
- **~1,569 concept cards** from 7 authoritative sources serving as the reference base
- **0 Node.js imports** in any final guide (after the one that was caught in review)
- **14 guides planned** total, with the remaining 7 ready to produce using the same pipeline

The `ai-js` repo would go on to serve as CC's ground truth for every line of JavaScript in the lykn project -- the same way `ai-rust` had been doing for the Rust code all along. The quality bar had been set, and it was set high.

---

*Note: `ai-js` was later moved into the C&B `ai-design` repo here: <https://github.com/cnbb-design/ai-design/tree/main/guides/js>*
