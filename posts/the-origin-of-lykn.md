---
layout: post.liquid
title: "The Origin of Lykn"
description: "From 'what was that Scheme thing?' to shipping a language in two nights."
published_date: 2026-03-26 00:00:00 +0000
is_draft: false
---

## The Starting Point: A Forgotten Script Tag

It started with a simple question, the kind you ask when you're procrastinating on something else or just poking around old projects. Duncan remembered that the LFE website -- lfe.io, the site for Lisp Flavoured Erlang -- had some JavaScript on it that wasn't really JavaScript. It was s-expressions. In a `<script>` tag. Running in the browser. He couldn't remember what it was called.

The question to Claude was roughly: "I'm looking for something that looks like a Lisp but compiles to JS. ClojureScript is too heavy. I want something super lightweight. I think I used something like that on the LFE site?"

So we went hunting. Claude rattled off a bunch of candidates -- Wisp, Parenscript, LispyScript, eslisp -- but none of them rang the bell. Then Duncan found it in the lfe.io source:

```html
<script src="/js/biwascheme.js">
  (let* ([quotes (list "\"A proper Lisp.\""
                       ...)])
    (define set-quote (lambda ()
      (set-content! "#lfe-tagline" (get-quote))))
    (set-timer! set-quote 10))
</script>
```

BiwaScheme. A Scheme interpreter written in JavaScript, running inline in the browser. No build step, no transpilation -- just drop in `biwascheme.js` and write Scheme directly in your HTML. Elegant and perfectly on-brand for an LFE site.

## The Comparison Rabbit Hole

This kicked off a comparison. How does BiwaScheme stack up against the other JS Lisps? The conversation mapped out the landscape:

- **BiwaScheme vs LIPS Scheme** -- Both real Scheme interpreters in JS, but BiwaScheme has that killer inline `<script>` workflow with built-in DOM helpers.
- **BiwaScheme vs Wisp** -- Fundamentally different. Wisp is a compiler (Lisp disappears at build time), BiwaScheme is an interpreter (Lisp runs live in the browser).
- **BiwaScheme vs eslisp** -- Same distinction. eslisp is a thin syntactic mapping to the JS AST. No runtime, no interpreter. Just s-expressions in, JS out.
- **BiwaScheme vs Parenscript** -- Different worlds entirely. Parenscript requires a Common Lisp host.

Each tool occupied a different point in the design space, and none of them was quite what Duncan wanted.

## The Real Question Emerges

The comparison surfaced a deeper question: what does Duncan actually want for front-end work? The constraints crystallized quickly:

- S-expression syntax (Lisp, not necessarily Clojure-flavored)
- Compiles to clean JS (no runtime, no interpreter overhead)
- Tiny -- the compiler itself should be small and comprehensible
- Could plausibly run the compiler in-browser for a BiwaScheme-like `<script>` tag workflow
- No heavy toolchain (no TypeScript, no webpack, no babel, no enormous node_modules)

This was the moment the conversation shifted from "which existing tool should I use" to "does the tool I want actually exist?"

## Squint, Wisp, eslisp, Fennel -- and Why None Quite Fit

Claude ranked the existing options by how well they'd match Duncan's preferences:

1. **Squint** (borkdude's lightweight ClojureScript dialect) -- closest match on paper, but Duncan's reaction was immediate: "it just seems so _huge_." And he was right. Even a "lightweight" ClojureScript carries the Clojure standard library tax.

2. **Wisp** -- beautiful philosophy ("markdown for JavaScript"), but in maintenance mode. The community is quiet.

3. **Fennel** -- genuinely lovely language design, but it compiles to Lua, not JS. Getting it into the browser means going through Fengari (a Lua VM in JS), which adds indirection.

4. **eslisp** -- the most intriguing. Maximally transparent: just an s-expression encoding of the ESTree AST format. Macros are plain JS functions. Tiny core. No opinions about data structures or semantics. But it was abandoned six years ago, written in LiveScript (itself a dead language), and only supported ES5.

Duncan kept circling back to eslisp. He liked its bare-bones philosophy. He asked: could he use it like BiwaScheme -- inline in `<script>` tags?

The answer was no. eslisp is a compiler, not an interpreter. It's a Node.js program that reads `.esl` files and outputs `.js` files. There's no browser runtime.

## The Fork in the Road

This led to a pointed question from Duncan: would it be easier to add an interpreter to eslisp, or add a compiler to BiwaScheme?

The analysis was clear:

**Adding a compiler to BiwaScheme would be very hard.** BiwaScheme implements real Scheme semantics -- first-class continuations, proper tail calls -- features that don't map cleanly to JavaScript. That's why it uses a VM internally. Compiling that to standalone JS would mean implementing something like Cheney-on-the-MTA, producing unreadable CPS-transformed output, and shipping a runtime library anyway.

**Adding an interpreter to eslisp would be... kind of pointless.** eslisp doesn't have its own semantics. There's nothing to "interpret" that JS doesn't already interpret. What you could do is bundle the eslisp compiler for the browser and have it compile-then-eval at page load.

But then: eslisp is six years old. Written in LiveScript. Only supports ES5. No arrow functions, no `const`/`let`, no destructuring, no `async`/`await`, no modules. The JS world has moved on enormously.

## "Would It Be Worth Doing a Full-On Port?"

This was the pivotal question. Duncan asked whether to port eslisp to modern JS or treat it as a reference implementation for something designed from scratch.

The answer was clear: **design from scratch, use eslisp as reference.** The reasons:

- JS has gained dozens of new syntax features since eslisp's last commit (optional chaining, nullish coalescing, top-level await, private class fields, logical assignment operators, etc.)
- Each of these requires new ESTree AST node types that eslisp doesn't know about
- The dependency situation has shifted -- escodegen (which eslisp uses) is slow and heavy, while astring is 10x faster and 6.5x smaller with zero dependencies
- The module system is completely different (CommonJS to ES modules)
- A fresh design means ES modules from day one, which matters for tree-shaking and the browser bundle story

What to keep from eslisp: the core insight that s-expressions map to ESTree AST nodes, and that macros are just JS functions that return AST fragments.

## The Toolchain Conversation

Before committing to building a new language, Duncan wanted to understand the lightest-weight JS development setup possible. The answer surprised him:

**For the compiler itself:** literally nothing. Just `.js` files and `<script>` tags. Modern browsers support ES modules natively.

**For dev tooling:** Biome (a single Rust binary for linting and formatting -- `brew install biome`), Deno or Bun for test running, and astring vendored as a single file. No npm in the development workflow.

**For the Rust side:** cargo. That's it.

The dev chain that emerged was remarkably lean:

| Tool | Purpose | Install |
|---|---|---|
| Biome | Lint/format JS | Single Rust binary |
| Deno | Test runner | Single Rust binary |
| astring | ESTree to JS | One vendored file (~16KB) |
| ESTree spec | AST reference | Read on GitHub |
| eslisp | Macro reference | Read the source |
| A browser | Smoke testing | Already have one |

Duncan, a Rust enthusiast, was delighted: "Deno is also Rust!"

## The Name

With the toolchain settled and the architecture taking shape, it needed a name. The conversation about Biome -- a Rust-based JS tool -- got Duncan thinking about biological metaphors. A JS Lisp is a kind of symbiosis, like lichen -- a composite organism of fungi, algae, and bacteria, ancient and resilient, growing on anything, not needing much.

Riffs followed: `lichen`, `lichn`, `liken` (too much like the English verb), `lykn`...

Then Duncan checked: `lykn` means "good luck" in Norwegian, "luck" in Swedish, and -- if you squint at the Icelandic -- could be translated as "closure."

A Lisp dialect where the name means "closure" in a Nordic language. That's the kind of coincidence that isn't really a coincidence.

The name was checked across registries: free on npm, free on jsr.io, free on crates.io. Green lights across the board.

## "We Could Write the Linter, Formatter, Interpreter, and REPL in Rust!"

This was the moment it became real. Duncan realized the architecture split naturally into two worlds:

- **JS compiler** (because it targets JS and needs to run in the browser)
- **Rust tools** (linter, formatter, syntax checker, REPL -- fast, single binary, no runtime deps)

The Rust side is where Duncan lives. Writing a s-expression reader, formatter, and REPL in Rust is the kind of project he'd do for fun on a weekend. And shipping it as a single binary via crates.io, alongside the JS compiler on npm and jsr.io -- that's a clean, modern, multi-registry distribution story.

"Yeah, okay... this just became a thing."

## Building the PoC: Night One (March 23)

With the design principles settled, we built the minimal proof of concept in a single session:

**The s-expression reader** (~90 lines of JS): parses lykn source text into a simple AST of atoms, strings, numbers, and nested lists.

**The compiler** (~250 lines of JS): walks the s-expression AST and emits ESTree nodes. A table of built-in "macros" maps form names (`const`, `let`, `if`, `=>`, `.`, `+`, etc.) to AST constructors. The output is fed to astring, which generates the final JS string.

**The CLI** (~40 lines): `lykn compile main.lykn` reads a file and writes JS to stdout.

**The Rust tools** (~200 lines total): a reader (mirroring the JS reader), a formatter (pretty-prints s-expressions with consistent indentation), and a CLI providing `lykn fmt` and `lykn check`.

**An example file** (`main.lykn`):

```lisp
(const greeting "hello, world")
(const greet (=> (name)
  ((. console log) (+ greeting ", " name "!"))))
(greet "lykn")
```

Compiled to:

```js
const greeting = "hello, world";
const greet = name => console.log(greeting + ", " + name + "!");
greet("lykn");
```

Clean. Readable. No runtime. Just JS you'd write by hand, expressed in s-expressions.

The PoC was tested, packaged, and ready for publishing across three registries: npm, jsr.io, and crates.io.

## Publishing and the Research Phase: Night Two (March 24)

Duncan published lykn v0.1.0. Three registries, one language, shipped.

Then came the disciplined part: we paused. No more code until we had a clear design.

Claude wrote detailed instructions for Claude Code (Duncan's implementation collaborator) to do research: clone the ESTree spec, astring's source, and eslisp's codebase, and produce structured analysis:

1. **ESTree inventory** -- every AST node type, by ES version, with properties
2. **Astring coverage** -- which nodes astring can generate (the ceiling for what lykn can emit)
3. **Eslisp macro table** -- the reference mapping from s-expression forms to AST nodes
4. **Gap analysis** -- what lykn 0.1.0 handles vs what's missing, with proposed syntax for each missing form
5. **Browser shim reference** -- how BiwaScheme and Wisp handle `<script>` tag registration

Key design decisions were locked in before the research started:

- **Colon syntax for member access**: `(console:log "hi")` instead of `((. console log) "hi")`. ZetaLisp/Common Lisp style.
- **Auto camelCase**: `my-function` in lykn becomes `myFunction` in JS output.
- **No user macros yet**: built-in forms only for v0.2.
- **No framework integration concerns**: pure language design first.

Claude Code completed all five research documents, producing ~70KB of structured analysis. The research phase was done.

## What Made This Work

Looking back at the two-night arc, a few things stand out about how this design process worked:

**Starting from a real need, not an abstraction.** Duncan didn't set out to design a language. He wanted to write some JS for a website without dealing with TypeScript toolchains. The language emerged from exploring that constraint.

**Exhaustive survey before commitment.** We looked at every plausible existing tool -- BiwaScheme, Wisp, Squint, Cherry, eslisp, Fennel, LispyScript, LIPS Scheme -- before concluding that the right tool didn't exist. This wasn't NIH syndrome; it was genuine due diligence.

**Separation of concerns.** The architecture split between JS (compiler, browser bundle) and Rust (dev tools, formatter, REPL) fell out naturally from the constraints. Each language is used for what it's best at.

**Ship first, then think.** The v0.1.0 PoC was deliberately minimal -- just enough to prove the concept works and claim the names across registries. All the deep design work comes after, informed by real research.

**Design before implement.** The research phase produced five structured documents before any v0.2 code was written. Every design decision will be documented before it's implemented. Duncan, as an experienced language designer (he's a core contributor to LFE), knows that the cost of fixing a bad design decision after implementation dwarfs the cost of thinking carefully upfront.

The journey from "what was that Scheme thing on the LFE site?" to a published, tri-registry language project with a name, a philosophy, a dev toolchain, and a research corpus -- took two evenings. The real work, of course, is just beginning.
