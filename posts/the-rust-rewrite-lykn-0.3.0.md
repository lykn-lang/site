---
layout: post.liquid
title: "The Rust Rewrite — lykn 0.3.0"
description: "The compiler is rebuilt in Rust, gaining algebraic types, exhaustive pattern matching, threading macros, and cells."
published_date: 2026-04-05 06:33:12 +0000
is_draft: false
---


Last time we shipped macros and I hinted at a Rust rewrite. Well, it happened. The lykn compiler is now a Rust binary, and the language grew substantially in the process.

This is the big release. Not because of Rust itself (though the speed is nice), but because of what Rust made practical to build: algebraic data types, exhaustive pattern matching, multi-clause function dispatch, contracts, threading macros, and controlled mutation through cells. The language went from "a nice Lisp syntax for JS" to something with real opinions about how programs should be structured.

## The two-layer design

The Rust rewrite formalized something that was implicit in 0.1.0: lykn has two syntax layers.

**Surface syntax** is what you write. It's ergonomic, keyword-based, and opinionated. `func`, `bind`, `type`, `match`, `cell`, `swap!` -- these are the forms in the tour and the reference.

**Kernel syntax** is the compilation target. Surface forms expand to kernel forms, which are closer to raw JavaScript. `const`, `let`, `function`, `=>`, `if` -- the primitives.

The Rust pipeline makes this explicit:

```
source --> reader --> expander --> classifier --> analyzer --> emitter --> codegen --> JS
```

The classifier parses s-expressions into a typed surface AST. The analyzer does type checking and exhaustiveness analysis. The emitter lowers surface forms to kernel s-expressions. Codegen turns those into JavaScript text. Every stage is a separate Rust crate, independently testable. About 80 emitter tests verify the surface-to-kernel transformation.

## Algebraic data types

`type` defines sum types with named, typed fields:

```lisp
(type Shape
  (Circle :number radius)
  (Rect :number w :number h)
  (Point))
```

```js
function Circle(radius) {
  if (typeof radius !== "number")
    throw new TypeError(/* ... */);
  return { tag: "Circle", radius };
}
function Rect(w, h) {
  return { tag: "Rect", w, h };
}
const Point = { tag: "Point" };
```

Each variant is a constructor function returning a tagged object. Zero-field variants like `Point` are constants. The type checker knows about these tags, which is what makes exhaustive matching possible.

## Pattern matching with exhaustiveness

`match` dispatches on variant tags, and the compiler uses Maranget's algorithm to verify that every variant is covered:

```lisp
(func area
  :args ((s :Shape))
  :returns :number
  :body
  (match s
    ((Circle r)  (* Math:PI r r))
    ((Rect w h)  (* w h))
    ((Point)     0)))
```

If you forget a variant -- say you add `Triangle` to `Shape` but don't update the `match` -- you get a compile-time error, not a runtime crash. This is the kind of safety guarantee that's hard to bolt on after the fact. Building it into the compiler from the start means it works everywhere, automatically.

The prelude ships with `Option` and `Result`:

```lisp
(type Option (Some :any value) None)
(type Result (Ok :any value) (Err :any error))
```

These work exactly like you'd expect from Rust or OCaml, but compile to plain JavaScript objects.

## Multi-clause functions and contracts

`func` gained multi-clause dispatch and pre/post contracts:

```lisp
(func factorial
  (:args ((n :number)) :returns :number
   :pre ((>= n 0))
   :body
   (if (= n 0) 1 (* n (factorial (- n 1))))))
```

The `:pre` clause generates a runtime assertion that fires before the body executes. `:post` can check the return value. These are development-time guardrails that get stripped in production builds, just like type annotations.

Multi-clause dispatch lets you write functions with multiple signatures:

```lisp
(func describe
  (:args ((s :string)) :body (template "string: " s))
  (:args ((n :number)) :body (template "number: " n)))
```

## Threading macros

Threading macros turn deeply nested function calls into readable pipelines:

```lisp
;; thread-first: value becomes the first argument
(-> user
  (get :name)
  (string:to-upper-case))

;; thread-last: value becomes the last argument
(->> items
  (filter even?)
  (map double)
  (reduce + 0))

;; some-threading: short-circuits on null/undefined
(some-> response
  (get :data)
  (get :users)
  (get 0))
```

The `->` form threads the value as the first argument to each subsequent call. `->>` threads as the last argument. `some->` wraps each step in a null check and short-circuits if anything is nullish. These are compile-time transformations -- the output is just nested function calls or method chains, no runtime overhead.

## Cells: controlled mutation

Mutation in lykn is explicit and contained. `cell` creates a mutable container, `swap!` applies a function to update it, `reset!` sets it directly, and `express` reads the current value:

```lisp
(bind counter (cell 0))
(swap! counter (fn (:number n) (+ n 1)))
(console:log (express counter))
;; --> 1
```

```js
const counter = { value: 0 };
counter.value = ((n) => n + 1)(counter.value);
console.log(counter.value);
```

The `!` suffix convention makes mutation visually obvious at every call site. If you see a `!`, state is changing. If you don't, it's pure.

## JS interop via js: namespace

Sometimes you need to drop down to raw JavaScript constructs. The `js:` namespace provides escape hatches:

```lisp
(js:typeof x)          ;; --> typeof x
(js:instanceof obj Cls) ;; --> obj instanceof Cls
(js:void 0)            ;; --> void 0
```

This keeps the interop explicit and greppable without polluting the core language.

## The CLI

lykn 0.3.0 ships as a proper CLI tool:

```sh
lykn compile main.lykn              # output to stdout
lykn compile main.lykn -o main.js   # output to file
lykn compile main.lykn --strip-assertions  # production mode
lykn fmt main.lykn                  # format lykn source
lykn check main.lykn               # syntax check without compiling
```

Single binary. No runtime dependencies (well, one -- Deno is still involved for user-defined macro expansion, since macros are written in lykn and need a JS runtime to evaluate. We're working on that.)

## Two weeks in

From first commit to 0.3.0: two weeks. The language now has algebraic types, exhaustive pattern matching, threading macros, cells, contracts, a Rust compiler, and a CLI. The JS compiler still works and powers the browser bundle. Both implementations share the same syntax and semantics.

## What's next

That Deno dependency for macro expansion? It's the last external dependency in the Rust pipeline. Eliminating it means lykn becomes fully self-contained -- pure Rust from source to JS output. That, plus some operator ergonomics work and a big push on documentation.
