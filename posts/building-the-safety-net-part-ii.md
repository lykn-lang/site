---
layout: post.liquid
title: "Building the Safety Net, Part II"
description: "Guides 8 through 12: performance, anti-patterns, project structure, documentation, and the Deno series."
published_date: 2026-03-28 00:00:00 +0000
is_draft: false
---

[Part I](/posts/building-the-safety-net.html) covered how we built Guides 1-7 from 1,569 concept cards. This session tackled Guides 8 through 12 -- the guides that deal with how you *organize* JavaScript code, not just how you write it.

## The AI Optimization Trap

The Performance guide's most important decision was structural: measurement discipline leads the entire guide. The first four idioms are about profiling, benchmarking, and microbenchmark traps. Every optimization technique that follows is implicitly downstream of "did you measure?"

This wasn't just about good engineering practice. It was about Claude Code specifically. The single most damaging performance anti-pattern in AI-generated code is premature optimization -- trading readability for negligible gains in non-bottleneck code. By opening with measurement and closing with a "What NOT to Micro-Optimize" section, we created bookends that frame every optimization as *conditional on evidence*.

The concept card coverage for performance was thinner than for the language-mechanics guides -- there are no dedicated "performance" cards in the books. So the guide synthesizes performance implications from cards about other topics: sparse arrays, prototype chains, Map/Set mechanics, garbage collection, lazy evaluation. The prompt explicitly told Claude Code to stay grounded in observable behavior rather than speculating about V8 internals.

## The Inverted Guide

Guide 09 (Anti-Patterns) was structurally different from everything before it. Guides 01--08 teach what *to* do. Guide 09 is a dedicated catalog of what *not* to do -- with its own strength levels (MUST-AVOID, SHOULD-AVOID, CONSIDER-AVOIDING) and a format that leads with the anti-pattern, then shows the fix.

The key design tension: the existing guides already had 84 distinct "Bad" examples between them. Guide 09 needed to add value beyond those, not just restate them. Each proposed entry got an annotation -- does it *amplify* an existing guide's coverage, or is it a cross-cutting anti-pattern that spans multiple guides?

This guide also introduced a structural innovation that propagated forward: Related Guidelines sections listing specific ID numbers per guide. Instead of "See Guide 03 for error handling," it says "`03-error-handling.md` IDs 18, 19, 20, 21, 22, 24, 36." Immediately more useful for navigation.

## Where AI Scaffolding Goes Wrong

The Project Structure guide had a flagship entry on flat-by-feature vs nested-by-type. This addresses the most impactful structural decision, and the one where AI-generated scaffolding most often defaults to the wrong answer -- `controllers/`, `models/`, `services/` -- because that's what's most common in training data.

The circular imports entry earned MUST strength. ESM circular imports are genuinely nasty -- the module graph resolves, but bindings can be `undefined` at access time because the dependent module hasn't finished initializing. The concept cards documented this mechanism precisely, and it deserved thorough treatment.

## "Don't Comment Obvious Code"

The Documentation guide has one entry that might be the most important single paragraph in the entire guide series. It shows the classic AI-generated comment pattern:

```js
// Import the path module
import { join } from "@std/path";

// Define the maximum number of retries
const MAX_RETRIES = 3;

// Create an async function to fetch user data
async function fetchUser(id) { ... }
```

Then shows the same code with no comments, which is perfectly self-documenting. The entry name: "Don't Comment Obvious Code -- The AI Anti-Pattern."

## The Deno Series

We split the Deno guide into four focused chapters rather than one monolith. The most interesting design decision: inverting the source priority. Every guide up to this point had Exploring JS as the most authoritative source. For the Deno chapters, the Deno concept cards became primary and the JS language cards became secondary. This is a runtime guide, not a language guide.

The Testing chapter turned out to be one of the most practically useful in the series. The HTTP handler testing pattern -- constructing `Request` objects and asserting on `Response` without starting a server -- is Deno's killer testing feature.

The Task Runner chapter was the most recipe-oriented. Less "why" and more "here's the command." The `check` task recipe -- `biome ci && deno check **/*.js && deno test --allow-all` -- is arguably the single most valuable artifact for day-to-day development.

---

*Five guides, one night. Part III will cover the Biome series and the No-Node Boundary -- the capstone that ties it all together.*
