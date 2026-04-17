---
layout: post.liquid
title: "Pure Rust — lykn 0.4.0"
description: "No more Deno dependency. Sane equality operators. Keyword-method threading. Fifteen developer guides."
published_date: 2026-04-13 06:16:34 +0000
is_draft: false
---


Last time we rebuilt the compiler in Rust but kept one thread tied to the old world: user-defined macros still shelled out to Deno for evaluation. That dependency bothered me. A "self-contained" compiler that requires a 100MB JavaScript runtime isn't really self-contained.

lykn 0.4.0 cuts that thread. The Rust compiler now handles the entire pipeline from `.lykn` source to JavaScript output with no external dependencies. One binary. No Deno. No Node. No subprocess calls. Pure Rust.

## How we got rid of Deno

The challenge was macro expansion. Macros are written in lykn, which means evaluating them requires running lykn code. The 0.3.0 approach was pragmatic: shell out to Deno, run the JS compiler's expander, get the results back. It worked, but it was slow and fragile.

The 0.4.0 approach moves macro expansion entirely into the Rust pipeline. The expander now evaluates quasiquote templates, handles gensym generation, and performs substitution all in Rust. User macros go through the same three-pass pipeline (collect, expand, emit), but every pass runs natively. The result: macro expansion is fast, and the compiler is truly self-contained.

## Sane equality (DD-22)

This is a design decision I'd been thinking about since 0.1.0. In kernel syntax, `=` is assignment (matching JavaScript). But in surface syntax, you never assign -- you `bind`. So what should `=` mean?

The answer, formalized as DD-22: `=` is strict equality in surface syntax.

```lisp
(= a b)       ;; --> a === b
(!= a b)      ;; --> a !== b
(= a b c)     ;; --> a === b && b === c  (variadic)
```

This matches every other Lisp dialect, where `=` is a comparison. It also means you can't accidentally assign when you meant to compare. The kernel form for assignment still exists (`(= x 1)` in kernel syntax), but surface syntax won't let you reach for it.

Logical operators got the same treatment:

```lisp
(and x y)     ;; --> x && y  (short-circuit)
(or x y)      ;; --> x || y  (short-circuit)
(not x)       ;; --> !x
```

These are operators, not functions. They short-circuit properly. `(and false (expensive-call))` never calls `expensive-call`.

## Keyword-method threading

Threading macros got a new trick. When you thread through a pipeline and need to call a method on the threaded value, use the keyword-method syntax:

```lisp
(->> #a(1 2 3 4 5 6 7 8 9 10)
  (:filter (fn (:number n) (= (% n 2) 0)))
  (:map (fn (:number n) (* n 10)))
  (:reduce + 0))
```

```js
[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  .filter((n) => n % 2 === 0)
  .map((n) => n * 10)
  .reduce((a, b) => a + b, 0);
```

The `:method` syntax tells the threading macro to call `.method()` on the threaded value instead of passing it as an argument. This makes array method chains, promise chains, and DOM manipulation read naturally in a pipeline style.

You can also use it with `->` for thread-first:

```lisp
(-> "hello world"
  (:to-upper-case)
  (:split " ")
  (:join "-"))
;; --> "HELLO-WORLD"
```

## Fifteen developer guides

The language reference tells you what each form does. But how do you structure a real application? How do you handle errors? What patterns work well for async code?

lykn 0.4.0 ships with fifteen developer guides in the book covering practical patterns:

- **Getting Started** -- installation, first project, the compilation model
- **Bindings and Scope** -- `bind`, destructuring, scope rules
- **Functions** -- `func`, `fn`, multi-clause dispatch, contracts
- **Types and Pattern Matching** -- `type`, `match`, exhaustiveness, `if-let`/`when-let`
- **Mutation** -- cells, `swap!`/`reset!`/`express`, when mutation is appropriate
- **Error Handling** -- `Option`, `Result`, `try`/`catch`, when to use which
- **Collections** -- arrays, objects, `assoc`/`dissoc`/`conj`, immutable updates
- **Threading** -- `->`, `->>`, `some->`, keyword methods, pipeline patterns
- **Macros** -- `macro`, quasiquote, hygiene, `import-macros`, macro design patterns
- **Modules** -- ES module compilation, exports, project structure
- **Async Patterns** -- `async`/`await`, promise chains, error propagation
- **Classes** -- when to use classes vs. types, extending JS libraries
- **Browser Development** -- the shim, `<script type="text/lykn">`, the JS API
- **Testing** -- test structure, assertions, mocking patterns
- **Interop** -- `js:` namespace, calling JS libraries, TypeScript declaration files

Each guide is standalone but references the others. The goal is that you can go from "I've never seen lykn" to "I'm building something real" in an afternoon.

## Three weeks

It's been three weeks since the first commit. The compiler is self-contained Rust. The language has algebraic types, exhaustive pattern matching, macros, threading, cells, and sane operators. The documentation covers fifteen practical topics. The browser bundle is 73KB.

And we're not done yet.

## What's next

One piece is missing from the mutation story: external property mutation. Cells handle internal state beautifully, but sometimes you need to set a DOM property or update a library object. `set!` is coming, and with it the complete mutation model for lykn.
