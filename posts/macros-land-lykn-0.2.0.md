---
layout: post.liquid
title: "Macros Land — lykn 0.2.0"
description: "Quasiquote, hygiene, and cross-module macro composition arrive one day after launch."
published_date: 2026-03-28 02:52:29 +0000
is_draft: false
---


Last time we shipped a working Lisp-to-JavaScript compiler in three days. I closed that post saying macros would take "about a day."

It took two days. Close enough.

lykn 0.2.0 ships with a full macro system: `defmacro` with quasiquote and unquote, automatic gensym hygiene, a three-pass expansion pipeline, and cross-module macro composition via `import-macros`. This is the feature that makes lykn a Lisp and not just "JavaScript with parentheses."

## Why macros matter here

Most compile-to-JS languages give you exactly the abstractions the language designer thought of. If you want something new -- a custom control flow form, a DSL for your domain, a `when` that's cleaner than `if` without an else branch -- you're out of luck. You get functions and that's it.

With macros, you extend the compiler. At compile time. No runtime cost. The macro runs, produces new s-expressions, and those get compiled to JS like everything else. Your custom forms are indistinguishable from built-in ones.

## defmacro with quasiquote

Here's the classic example -- a `when` form that only evaluates its body if the test passes:

```lisp
(macro when (test (rest body))
  `(if ,test (block ,@body)))
```

The backtick (`` ` ``) is quasiquote -- it templates s-expressions. The comma (`,`) unquotes a single value. The `,@` splices a list. So when you write:

```lisp
(when (> x 0)
  (console:log "positive")
  (do-something x))
```

The macro expands to:

```lisp
(if (> x 0)
  (block
    (console:log "positive")
    (do-something x)))
```

Which compiles to:

```js
if (x > 0) {
  console.log("positive");
  doSomething(x);
}
```

Your abstraction cost: zero bytes at runtime.

## Hygiene via gensym

Macros that introduce bindings need to avoid capturing names from the call site. lykn uses automatic gensym -- the `#` suffix convention borrowed from Fennel:

```lisp
(macro with-timing (label (rest body))
  `(block
     (const start#gen (Date:now))
     ,@body
     (console:log ,label (- (Date:now) start#gen))))
```

Every use of `start#gen` gets a unique generated symbol like `start__gensym42`. No accidental name collisions. You can also call `(gensym "prefix")` directly if you need programmatic control.

## The three-pass pipeline

Macro expansion happens in three passes, and the ordering matters:

1. **Collect** -- scan top-level forms, register macro definitions and `import-macros` declarations
2. **Expand** -- walk the AST, expanding macro calls using Bawden's quasiquote algorithm
3. **Emit** -- the expanded forms go to the compiler, which sees only primitive forms

The three-pass design means macros can reference other macros defined later in the same file, and `import-macros` makes cross-file composition work cleanly:

```lisp
;; utils.lykn
(macro unless (test (rest body))
  `(if (not ,test) (block ,@body)))

(macro when-let (bindings (rest body))
  `(block
     (const ,@bindings)
     (when ,(car bindings) ,@body)))
```

```lisp
;; app.lykn
(import-macros "./utils.lykn" (unless when-let))

(unless (= status "error")
  (console:log "all clear"))
```

The imported macros expand at compile time in the importing module. No runtime import. No extra JS in the output. The compiled `app.js` just has the `if` statement.

## Cross-module composition

This is the part I'm most pleased with. `import-macros` doesn't just copy macro definitions -- it runs them through the same three-pass pipeline in the source module first, so macros can build on other macros. You can write a macro library, distribute it, and users get the same expansion guarantees as if they'd written the macros inline.

The browser shim supports inline `macro` definitions (you can define and use macros right in a `<script type="text/lykn">` tag), though `import-macros` isn't available there since there's no file system to import from.

## Five days in

Let me take stock. In five days from the first commit, lykn has:

- A complete s-expression reader with dispatch syntax (`#a(...)`, `#o(...)`, radix literals, block comments, expression comments)
- 24+ kernel forms covering all core JS constructs
- A macro system with quasiquote, hygiene, and cross-module composition
- A browser shim for `<script type="text/lykn">` development
- Type annotations with runtime checks
- Classes, modules, destructuring, async/await

All of it compiling to readable JavaScript with no runtime dependency.

## What's next

The JS compiler works. It's good enough for real projects. But I keep looking at it and thinking about Rust.

A Rust compiler would be fast -- really fast. Single binary, no runtime dependency on Deno or Node. And there are things I want to build (exhaustiveness checking for pattern matching, a real type system, proper error messages with source locations) that would be much more natural to express in Rust.

So... the rewrite is coming.
