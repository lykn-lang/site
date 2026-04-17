---
layout: post.liquid
title: "Building the Safety Net, Part III"
description: "The Biome series, the No-Node Boundary, and what we learned building 19 guides for an AI collaborator."
published_date: 2026-04-13 00:00:00 +0000
is_draft: false
---

[Part II](/posts/building-the-safety-net-part-ii.html) covered Guides 8-12: performance, anti-patterns, project structure, documentation, and the Deno series. Two and a half weeks later, we sat down for the final session.

## Resolving the Tooling Tension

The Biome/Deno overlap had been building since Guide 10, where `biome.json` first appeared alongside `deno.json`. Through the Deno Runtime Basics chapter (which noted "omit `lint`/`fmt` from `deno.json` when using Biome") and the Task Runner chapter (which showed `biome ci` in task recipes), we'd been deferring the full explanation. The Biome Setup chapter finally resolved it with a clean division-of-labor table: Biome handles lint and format, Deno handles type-checking, testing, and running.

## Curating, Not Cataloging

The Lint Rules chapter had the richest concept card library of the Biome series -- about 28 cards. The key design decision was curating rather than cataloging. Biome has 200+ rules; we listed only the 8--12 most relevant for a Deno plain-JS project, with cross-references back to the guide that teaches the underlying pattern. `noDoubleEquals` points to Guide 01's equality idiom. `noVar` points to Guide 01's declaration idiom. `useExhaustiveSwitchCases` points to Guide 05's discriminated union pattern.

This is the kind of thing that makes a guide genuinely useful rather than exhaustive-but-ignorable.

The Formatting chapter was deliberately the shortest in the entire series -- 16 entries. Formatting is a "configure once" topic. The opening entry states Biome's philosophy: "Biome functions as its own automatic style guide, not a tool for implementing other style guides." The goal is zero formatting discussions in code review.

## The Capstone

Guide 14 -- the No-Node Boundary -- consolidated every "no Node.js" thread from the entire series into a single, searchable reference. It's structured as a routing table: state the Node.js pattern, name the Deno replacement, cross-reference the guide that covers it in detail. Twenty-seven entries across seven categories.

The escape hatch section was important for honesty. The guide says `npm:chalk` is fine when there's no JSR equivalent. `nodeModulesDir` exists for a reason. Acknowledging the legitimate uses of Node.js compatibility makes the boundary credible rather than dogmatic.

The comprehensive Node.js-to-Deno replacement table at the end -- 30+ replacements across 8 categories with guide references -- is arguably the most valuable standalone artifact in the entire series.

## What We Learned

**Boundary management was harder than content generation.** The most difficult part of each prompt wasn't "what should this guide say?" but "what should this guide *not* say that another guide already covers?" By Guide 14, the boundary sections referenced specific IDs in specific guides.

**Innovations propagated forward.** Guide 09's inverted format. Guide 12's inverted source priority. Guide 13-01's division-of-labor table. Each structural innovation, once discovered, was adopted by every subsequent guide.

**The concept card ground truth kept us honest.** When card coverage was thin (performance, documentation), the prompts acknowledged it explicitly and told Claude Code to stay grounded rather than speculate. This prevented the guides from drifting into confident-sounding claims that no source supported.

**The guides taught Claude Code to not be Claude Code.** The deepest irony of the project is that several guides exist specifically to counteract Claude Code's own tendencies: the "don't comment obvious code" entry, the "don't use sequential await on independent operations" entry, the "don't emit `require()`" boundary. We were building a set of instructions for an AI to override its own training-data biases.

---

*Nineteen files. Two nights. One SKILL.md. And a JavaScript codebase that could finally stand next to its Rust sibling without embarrassment.*
