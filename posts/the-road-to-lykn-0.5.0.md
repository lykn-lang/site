---
layout: post.liquid
title: "The Road to Lykn 0.5.0 — Notes from the Workshop"
description: "A conversational retrospective on the design and discovery work behind the v0.5.0 release."
published_date: 2026-04-18 01:08:00 +0000
is_draft: false
---

When 0.4.1 shipped on April 14th, the compiler was in a good place --
the surface language had equality operators that made sense, `bind`
finally enforced its own type annotations, and we had `set!` for
external property mutation. The guides had been ported. The book had
chapter prompts lined up through Chapter 6. By most measures, we'd
just finished a pretty satisfying run.

Three days later, we're releasing 0.5.0.

It turns out that a release focused on *documentation* -- the JS
guides, the book, the AI-friendly SKILL.md -- surfaced a *pile* of
questions that weren't really about documentation at all. They were
about *shape*. What does a Lykn project look like when you're not
just authoring inside a monorepo? How do you ship a macro module?
How do you write tests in Lykn when the entire test suite is still
in JavaScript? What happens when someone writes `lykn new my-app`
and gets ... nothing, because we hadn't built it yet?

---

## Starting points: three loose threads

Going into this window, we had three unfinished stories pulling at
us:

**Destructured parameters.** DD-25 had actually been designed
*before* 0.3.0 -- all the way back when we were still arguing about
whether to use `obj-pat` or reuse `object` as a pattern form.
(Duncan's "in LFE, we use `(cons a b)` to get head/tail" settled it
in about six words. The constructor-is-destructor principle from
Erlang/ML became a Lykn principle on the spot.) But the
implementation had lagged, and the book's Chapter 15 still had that
awkward "current limitation" note hanging over it.

**Generators.** The book's Chapter 21 opened with a reference to
*The Holy Grail* and closed with a note that said, essentially,
*generators are deferred to v0.2.0+ -- Lykn syntax for `yield` is not
yet defined*. Hrm.

**Testing and publishing.** The testing bootstrap document had been
sitting in the project files since Guide 00 first revealed the
operator bug. We'd designed DD-30 (the testing DSL), DD-31 (the test
runner), and DD-32 (the migration plan from JS tests to Lykn tests).
But we hadn't actually built any of it. And then Duncan asked Claude
Code a perfectly innocuous question about whether `lykn publish`
would push the testing package to JSR, and *he* wrote back something
that started with "Here's the picture" -- which, as Duncan pointed out
at the time, is rarely a good sign from CC. The picture was: we had
never thought about publishing a macro module. At all.

---

## The destructuring trilogy

The first substantive work of the cycle was finishing destructured
parameters -- which, remember, had been designed almost six months
earlier. The DD had three parts:

- **DD-25**: the basic `(object ...)` and `(array ...)` patterns in
  `:args`, with per-field types
- **DD-25.1**: nested destructuring via `alias`, and `default`
  sub-forms
- **DD-25.2**: top-level `default` and `rest` directly in `:args`
  (the case where you want a defaulted scalar alongside destructured
  objects -- `((object :string host) (default :boolean ssl true))`)

The three-part structure is a bit unusual. Normally a single DD
covers a single feature. But destructuring has this fractal quality
where every "what about" question opens up another layer. What about
nested patterns? What about defaults inside nested patterns? What
about defaults *not* inside patterns? We cranked away for a few hours, at the end of which came this nice validation from Duncan:

> Those all look good -- very similar to LFE, in fact ;-)

Hello, Robert!

---

## Generators ... finally

Chapter 21 of the book had been mocking us for a while. Generators
are one of those features that JS developers either never use or use
constantly, and Lykn's promise is "thin skin over JS" -- so *not*
supporting them was a papercut every time someone looked at the
concept-card list.

The design conversation was surprisingly short. JS has `function*`
and `yield`; Lykn needed surface forms that felt like the rest of
the surface language. We'd already settled on the pattern -- `func`
is the surface cousin of `function`, `fn` is the surface cousin of
the arrow. Generators just needed the same treatment: `genfunc` for
the declaration form, `genfn` for the expression form.

The one novel bit was the `:yields :type` clause. Every other type
annotation in Lykn tells you what flows *in* or *out* of a function
(`:args`, `:returns`, `:pre`, `:post`). Generators yield values one
at a time, and we wanted those to be typed too. The syntax reuses
the keyword-clause pattern established by `func`:

```lisp
(genfunc range
  :args (:number start :number end)
  :yields :number
  :body
  (for (let i start) (< i end) (+= i 1)
    (yield i)))
```

---

## The `.lyk` extension

Small thing, but it matters. At some point -- I think when we were
writing the test runner, but it might have been earlier -- someone
(possibly CC, possibly Duncan) [Editor: it was Duncan ;-)] pointed out that we had Lykn source files in two distinct flavors: pure kernel (for low-level things
that ship in the compiler itself) and surface (for everything
users write). Treating them identically meant the tooling couldn't
give different error messages, and it meant the book couldn't tell
at a glance which examples needed the surface compiler.

`.lyk` for kernel, `.lykn` for surface. Tiny change, no DD
required, and it rippled through the CLI, the test runner, macro
entry resolution, and the publishing pipeline essentially for free.

---

## The great workspace restructuring

This is where the release goes from "add some features" to
"actually, let's think about what Lykn *is* as a project."

The problem was easy to describe and hard to solve: Lykn the
compiler, Lykn the browser bundle, and Lykn the testing framework
were all living together in `src/`, sharing a single `deno.json`,
and pretending to be one package. But they were not one package.
They had different publishing stories, different consumers,
different tooling needs. Shoving them all together was going to get
worse, not better, as we added more (a linter package, a formatter
package, probably a language server eventually).

The obvious move was Deno workspaces -- restructure into
`packages/lang/`, `packages/browser/`, `packages/testing/`, with a
root `project.json` declaring the workspace and each package
getting its own `deno.json`.

"Obvious" undersells how much had to actually change. Every import
path. Every test fixture. Every CI reference. The book's source
paths. The conversation bootstrap documents. The `CLAUDE.md`
workflow instructions. The scaffold template (which didn't exist
yet, but whose design had to anticipate the workspace layout).

---

## A unified CLI (mostly)

The other thing DD-28 did was turn `lykn` into a proper top-level
tool. Before 0.5.0, `lykn` was essentially a compiler with two or
three subcommands bolted on. After 0.5.0:

```
lykn new my-app        # scaffold a project
lykn run app.lykn      # compile + run
lykn test              # discover and run tests
lykn lint packages/    # lint compiled JS
lykn build --dist      # stage packages for publishing
lykn publish --jsr     # publish to JSR
lykn publish --npm     # publish to npm
```

The interesting design call here was deciding that `lykn` would be
a *wrapper around Deno*, not a replacement for it. Deno already
runs JS. Deno already runs tests. Deno already publishes to JSR.
We just needed `lykn` to handle the Lykn-specific steps (compile
`.lykn` to `.js`, discover test files by the Lykn conventions,
stage workspace packages) and then hand off to Deno for execution.

This is the same pattern as the testing DSL -- the testing macros
don't implement a test runner, they expand to `Deno.test()`
calls. Same philosophy at the CLI level: don't reinvent what the
platform gives you. Be thin.

---

## `lykn new`

Small change, big impact. `lykn new <name>` scaffolds a fresh workspace
with:

- A `project.json` declaring the workspace
- A `packages/<name>/` with a `deno.json` and a minimal example
- A `README.md`
- A `.gitignore`
- Everything wired up so `lykn run` and `lykn test` just work

The hardest part of designing this wasn't the scaffold itself -- it
was deciding *what the scaffold implies about the "standard" Lykn
project*. Because whatever `lykn new` emits becomes, by default,
what every Lykn project looks like. If we default to a single-package
layout, we're implicitly saying "most Lykn projects are single
packages." If we default to a workspace layout, we're saying
workspaces are the norm.

---

## The testing trilogy

Then came testing. This was the longest thread of the cycle.

**DD-30** was the testing DSL itself -- macros like `test`,
`suite`, `is`, `is-equal`, `ok`, `is-thrown`, `matches`. The big
design call here was: **don't build a test runner, be a macro
module that expands to `Deno.test()` calls**. Deno already has a
test runner. It does parallelism, filtering, watch mode, coverage,
four output formats, and sanitizers. The only thing missing was
Lykn syntax for authoring tests. So that's all DD-30 provides.

The naming was fun to argue about. I had initially proposed
`assert-equals` and `assert-throws` -- Deno-compatible naming,
familiar to JS developers. Duncan pushed back on the `assert-` prefix
as verbose and noisy. We looked at uvu (a minimalist JS test
framework) and liked their short forms, and Duncan mentioned his time spent with Clojure and LFE testing DSLs. `is`, `is-equal`, `ok` --
each one short enough that a test file reads like prose:

```lisp
(test "arithmetic"
  (is-equal (+ 1 1) 2))
```

**DD-31** was the `lykn test` CLI. Discovery conventions (`*_test.lykn`,
`*.test.lykn`, and the `.lyk` variants), compilation pipeline,
passthrough to Deno. The novel bit is Markdown doc testing -- `lykn
test` can find Lykn code blocks embedded in Markdown files and
check that they compile. This is what unblocks the book's Chapter
30 and the guide system: every code example in the docs can now be
verified automatically. No more silent drift between what the docs
say and what the compiler does.

**DD-32** was the migration plan -- five tiers by bootstrapping
distance, from "surface tests that treat the compiler as a black
box" (easiest, do first) to "expander tests that test the macro
system the test macros depend on"

---

## The publishing epiphany

Then came the publishing conversation, which started with Duncan
observing:

> You know what? For all of our work in the previous
> conversations, we haven't stopped to think about one very crucial
> bit ...

And then listing four major design threads -- the book, the testing
framework, the JS quality standards, part 1 and part 2 of that --
and noting that none of them had addressed how to *ship* Lykn code
as a consumable package.

CC had given a clear diagnosis: `@lykn/testing` was a macro module,
its `exports` pointed to `mod.lykn`, and neither JSR nor npm would
know what to do with that. The testing package was the canary, but
the same problem applied to *any* macro module anyone would ever
publish. This wasn't a testing-package problem, it was a Lykn-
publishing problem.

Duncan's predictable response:

> we need a solution for this that *any* project will be able to
> use. I think we need to double-down on our nascent use of a dist dir and fix this generally

- **runtime** -- compiled `.js` files with rewritten imports
  (regular Lykn library)
- **macro-module** -- `.lykn` sources plus a generated `mod.js`
  stub so npm consumers don't see a file extension they don't
  understand
- **tooling** -- plain JS, pass through

Every package declares its kind in its `deno.json`. `lykn build
--dist` produces a `dist/` tree where every package has exactly
what it needs for both JSR and npm publishing. `lykn publish`
then calls `deno publish` for JSR and iterates the workspace for
npm. Clean pipeline, one command.

**DD-34** fell out of DD-33 immediately. Once macro modules could
be *published*, consumers had to be able to *import* them. The
current `import-macros` only understood filesystem paths. It
needed to understand `jsr:@lykn/testing` and `npm:@lykn/testing`
and bare names through the workspace import map.

The design call here was architectural: **delegate registry
resolution to Deno**. We're already running a Deno subprocess for
macro compilation. Adding a `"resolve"` action to that subprocess
(where the Rust side asks "what's the cached disk path for
`jsr:@lykn/testing`?" and Deno answers) costs almost nothing.
Every future Deno registry feature -- new registries, new protocols,
whatever -- works for Lykn automatically. The alternative was
implementing JSR/npm resolution in Rust, which would have been
hundreds of lines of code that we'd have to maintain forever,
always playing catch-up with Deno upstream.

I'll admit I floated the catch-up idea briefly. Duncan didn't have to
say much -- just "let's not reinvent Deno's resolver" and it was
done.

---

# Artwork

Ending on a fun note, the 0.5.0 release of [The Lykn Book](https://cnbbooks.github.io/lykn/) has got gobs of otherworldly (and this-worldly, tbh) Lichen-inspired artwork: 39 images, 1 for each chapter ... and then some more for dessert at the end :-)
