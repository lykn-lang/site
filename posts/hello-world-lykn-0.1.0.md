---
layout: post.liquid
title: "Hello, World — lykn 0.1.0"
description: "A Lisp for JavaScript goes from idea to working compiler in three days."
published_date: 2026-03-26 06:13:12 +0000
is_draft: false
---


Three days ago this language didn't exist.

The question was simple enough: what if you could write JavaScript in s-expressions -- real s-expressions, with macros, with a reader -- and get clean, readable JS out the other side? Not a toy. Not an academic exercise. Something you could actually ship to a browser.

Seventy-two hours later, lykn 0.1.0 is real.

## What it is

lykn (Norwegian for "good luck," Swedish for "luck," and if you squint at the Icelandic, "closure") is a lightweight Lisp that compiles to JavaScript. The output looks like code you'd write by hand. There's no runtime. Nothing extra ships to the browser. Just JS.

The pipeline is straightforward:

```
.lykn source --> reader --> expander --> compiler --> JavaScript
```

The reader parses s-expressions. The expander handles macros. The compiler walks the AST and emits clean JS via ESTree and astring. That's it.

## Twenty-four forms

Version 0.1.0 ships with 24 forms covering all the core JS constructs you need to write real programs. Here's the flavor.

### Bindings

`bind` creates immutable bindings. Always `const`, always.

```lisp
(bind greeting "hello, world")
(console:log greeting)
```

```js
const greeting = "hello, world";
console.log(greeting);
```

That colon syntax -- `console:log` -- is one of my favorite things about lykn. Colons compile to dots: `console:log` becomes `console.log`, `obj:name` becomes `obj.name`, `Math:PI` becomes `Math.PI`. It's the Common Lisp package separator repurposed for property access, and it reads beautifully.

### Functions with types

`func` defines named functions with keyword-labeled clauses. Type annotations become runtime checks in development and get stripped in production builds.

```lisp
(func greet
  :args ((name :string))
  :returns :string
  :body (template "Hello, " name "!"))

(console:log (greet "world"))
```

```js
function greet(name) {
  if (typeof name !== "string")
    throw new TypeError("greet: arg 'name' expected string, got " + typeof name);
  const result = `Hello, ${name}!`;
  if (typeof result !== "string")
    throw new TypeError("greet: return expected string, got " + typeof result);
  return result;
}
console.log(greet("world"));
```

`fn` gives you arrow functions with the same type annotation support:

```lisp
(bind doubled
  (numbers:map (fn (:number x) (* x 2))))
```

### Classes from day one

Yes, lykn has classes. JS has classes, so lykn has classes.

```lisp
(class Counter ()
  (constructor (start)
    (assign this:count start))
  (increment ()
    (+= this:count 1)
    (return this:count)))
```

```js
class Counter {
  constructor(start) {
    this.count = start;
  }
  increment() {
    this.count += 1;
    return this.count;
  }
}
```

### In the browser

lykn ships with a browser shim. Include the bundle, write `<script type="text/lykn">`, and it just works:

```html
<script src="lykn-browser.js"></script>
<script type="text/lykn">
  (bind el (document:query-selector "#output"))
  (set! el:text-content "Hello from lykn!")
</script>
```

No build step. No bundler. Open the HTML file and go.

You also get a JS API for programmatic use:

```js
lykn.compile('(+ 1 2)')   // --> "1 + 2;\n"
lykn.run('(+ 1 2)')       // --> 3
```

## The speed of this

I want to be honest about the timeline because it's part of the story. March 23rd: first commit. March 26th: 24 forms, browser shim, type annotations, classes, modules, destructuring, a test suite, and a compiler that produces JS you're not embarrassed to read.

This isn't because the problem is easy. It's because targeting JavaScript from s-expressions is a remarkably good fit. S-expressions are already trees. JavaScript's AST (ESTree) is a tree. The compiler is mostly a matter of walking one and building the other.

## What's next

Macros. Real macros -- `defmacro` with quasiquote, hygiene, the works. The reader is ready for them; the expander just needs the three-pass pipeline. Should take about a day.

Famous last words.
