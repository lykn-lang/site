---
layout: post.liquid
title: "DOM Mutation — lykn 0.4.1"
description: "set! completes the mutation model. The full story of state in lykn."
published_date: 2026-04-14 05:26:01 +0000
is_draft: false
---


Short post today. lykn 0.4.1 adds `set!` for external property mutation, completing the language's mutation model.

## The problem

lykn is immutable-by-default. `bind` creates a `const`. You can't reassign it. If you need mutable state, you use a `cell` -- an explicit container with `swap!` and `reset!`.

But what about the outside world? The DOM, for instance:

```lisp
(bind el (document:query-selector "#title"))
;; How do I set el.textContent?
```

In 0.4.0 there was no clean way to do this from surface syntax. You could drop down to kernel syntax (`(= el:text-content "Hello")`), but that's assignment, not the intentional mutation that surface syntax is designed around. We needed a form that says "I am mutating an external property" with the same `!` visibility convention as the rest of the mutation model.

## set!

`set!` assigns a value to a property on an external object:

```lisp
(bind el (document:query-selector "#title"))
(set! el:text-content "Hello from lykn!")
(set! el:style:color "#2d5a27")
```

```js
const el = document.querySelector("#title");
el.textContent = "Hello from lykn!";
el.style.color = "#2d5a27";
```

The `!` suffix marks it as mutation, just like `swap!` and `reset!`. The colon syntax chains naturally for nested property access. It compiles to exactly the assignment you'd write by hand.

## The complete mutation model

With `set!`, lykn now has a complete, coherent story for mutation. Here's the full picture:

| Form | What it does | When to use it |
|------|-------------|----------------|
| `bind` | Immutable binding (`const`) | The default. Always start here. |
| `cell` | Mutable container (`{ value: x }`) | When you need local mutable state |
| `reset!` | Set a cell's value directly | Replacing cell state entirely |
| `swap!` | Update a cell via function | Deriving new state from old |
| `express` | Read a cell's current value | Accessing cell state |
| `assoc` | New object with updated key | Immutable object updates |
| `dissoc` | New object with key removed | Immutable key removal |
| `conj` | New array with appended item | Immutable collection growth |
| `set!` | Assign to external property | DOM, library objects, interop |

The first three columns of this table are the everyday tools. `bind` for values that don't change. `cell`/`swap!`/`reset!` for values that do. `assoc`/`dissoc`/`conj` for immutable collection updates. And `set!` for when you need to reach into the outside world.

## Compile-time safety

Every mutation form is visible at the call site. If a function mutates state, you'll see a `!` in its body. If it updates the DOM, you'll see `set!`. If it modifies a cell, you'll see `swap!` or `reset!`. There's no hidden assignment, no spooky action at a distance.

This is a deliberate design choice. Mutation isn't banned -- lykn targets JavaScript, and JavaScript is a mutable language. But mutation is always explicit, always marked, and always greppable. You can search your codebase for `!` and find every point where state changes.

## A quick DOM example

Putting it together -- a click counter using cells for internal state and `set!` for DOM updates:

```lisp
(bind count (cell 0))
(bind el (document:query-selector "#counter"))
(bind btn (document:query-selector "#increment"))

(btn:add-event-listener "click"
  (fn ()
    (swap! count (fn (:number n) (+ n 1)))
    (set! el:text-content (express count))))
```

```js
const count = { value: 0 };
const el = document.querySelector("#counter");
const btn = document.querySelector("#increment");

btn.addEventListener("click", () => {
  count.value = ((n) => n + 1)(count.value);
  el.textContent = count.value;
});
```

Clean. Every mutation is labeled. The compiled JS is what you'd write by hand.

## What's next

With the core language stable, the focus shifts to the toolchain and ecosystem. On the roadmap:

- **Project restructuring** -- separating the Rust compiler crates for independent versioning
- **`lykn new`** -- scaffold a new project with the right structure, a `mod.lykn`, and a test file
- **Package workspace** -- multi-package projects with shared dependencies and a single `lykn test` command

The language itself will keep evolving, but the foundation is solid. Three weeks from idea to a self-contained compiler with algebraic types, exhaustive pattern matching, macros, threading, cells, and a complete mutation model. Not bad for a language named "good luck."
