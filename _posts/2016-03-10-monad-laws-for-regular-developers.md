---
layout: post
title: "Monad laws for regular developers"
date: 2016-03-10
categories: learn fp
---

### Disclaimer
> This is not a monad tutorial. I am fresh meat on FP fields, I am currently on an exciting journey discovering and understanding all these concepts, thus errors may occur.

## What is a monad?
Well, it turns out, monads are just like almost everything else in computer science: a thing, which contains one ore more other things. Of course, they are more than that: with monads, we can define a pipeline, a series of computational steps, they allow us to reuse more of our code, to write it in terms of highly composable parts. Since composability should be a key concern to any developer, they are indeed very important. [Wikipedia] describes them in detail so I won't, I'd just like to highlight the _"programmable semicolon"_ analogy, which I like a lot:

> [...] monads have been described as "programmable semicolons"; a semicolon is the operator used to chain together individual statements in many imperative programming languages, thus the expression implies that extra code will be executed between the statements in the pipeline.

But ultimately, they are just boxes that must obey a set of laws.

## The laws
There are three laws of monads, namely the **left identity**, **right identity** and **associativity**.
Once you get them, they seem obvious, I think, but it is a bit hard for newbies like me to understand what they are actually stating.

## Why is it hard to understand?

[Googling around] for monad laws pops up quite a few results featuring Haskell.
The following definitions are from the [Haskell wiki]:

> **Left identity:**  `return a >>= f ≡ f a`
>
> **Right identity:** `m >>= return   ≡ m` 
>
> **Associativity:**  `(m >>= f) >>= g ≡ m >>= (\x -> f x >>= g)` 
 
Well, if you're like me and you're not quite familiar with Haskell, it doesn't mean much, does it? Return? What's that headless fish is doing in there?<br>
(Read carefully the [wikipedia] page I mentioned earlier and you'll get that, I promise)

Even putting this in sentences doesn't seem to help the poor, under-educated fellows like me. From [Learn You a Haskell]:

> **Left identity:** The first monad law states that if we take a value, put it in a default context with `return` and then feed it to a function by using `>>=`, it's the same as just taking the value and applying the function to it.
>
> **Right identity:** The second law states that if we have a monadic value and we use `>>=` to feed it to `return`, the result is our original monadic value.
>
> **Associativity:** The final monad law says that when we have a chain of monadic function applications with `>>=`, it shouldn't matter how they're nested.

When I spotted a link mentioning [scalaz] in the search results, I felt relieved, it must have scala examples, which must explain everything, let's see!

> **Left identity:**  `(Monad[F].point(x) flatMap {f}) assert_=== f(x)`
>
> **Right identity:** `(m forMap {Monad[F].point(_)}) assert_=== m`
>
> **Associativity:**  `(m flatMap f) flatMap g assert_=== m flatMap { x => f(x) flatMap {g} }`

Well, while it all makes sense now, back then it just didn't.

## Hope is not lost
There are a number of resources that can help getting started, I'd like to highlight [this one expressed in scala] in particular and [@dickwall]'s webinar entitled [What have the monads ever done for us] is also very, very helpful. These two helped me a lot to come up with the following human readable definitions.

### Left identity
If you have a box (monad) with a value in it and a function that takes the same type of value and returns the same type of box, then flatMapping it on the box or just simply applying it to the value should yield the same result.

Take scala's `Option` for example

```scala
val value = 1
val option = Some(value)
val f: (Int => Option[Int]) = x => Some(x * 2)
option.flatMap(f) == f(value)
```

I can even express it in javascript

```javascript
let value = 1;
let promise = Promise.resolve(value);
let f = (x) => Promise.resolve(x * 2)
promise.then(f) == f(value);
```

Well, that last line of javascript will actually return `false`, because if you `.then()` a promise, the nearest time it gets resolved is the [next tick]. This is true for the rest of the examples too, but I feel it would have been distracting to add `Promise.all()` around them, for example, or use some other trick to 'wait' for them to resolve.


### Right identity
If you have a box (monad) with a value in it and you have a function that takes the same type of value and wraps it in the same kind of box untouched, then after flatMapping that function on your box should not change it.

Again, with scala's `Option`

```scala
val option = Some(1)
option.flatMap(Some(_)) == option
```

And with javascript's `Promise`:

```javascript
let promise = Promise.resolve(1);
let wrapInPromise = (x) => Promise.resolve(x)
promise.then(wrapInPromise) == promise;
```

### Associativity
If you have a box (monad) and a chain of functions that operates on it as the previous two did, then it should not matter how you nest the flatMappings of those functions.

Again, see what it looks like with `Option`

```scala
val option = Some(1)
val f: (Int => Option[Int]) = x => Some(x * 2)
val g: (Int => Option[Int]) = x => Some(x + 6)

option.flatMap(f).flatMap(g) == option.flatMap(f(_).flatMap(g))
```

And in js with a `Promise` it reads:

```javascript
let promise = Promise.resolve(1)
let f = (x) => Promise.resolve(x * 2)
let g = (x) => Promise.resolve(x + 6)

promise.then(f).then(g) == promise.then((x) => f(x).then(g))
```

## Final thoughts
I hope this post achieved it's goal and you had your 'aha moment', just like I did before writing this (and during, a few times). If not, or you have some suggestions how to improve this, please tell me in the comments - constructive criticism is always very welcome.



[wikipedia]: https://en.wikipedia.org/wiki/Monad_(functional_programming)
[Googling around]: https://www.google.hu/search?q=monad+laws
[Haskell wiki]: https://wiki.haskell.org/Monad_laws
[Learn You a Haskell]: http://learnyouahaskell.com/a-fistful-of-monads#monad-laws
[scalaz]: http://eed3si9n.com/learning-scalaz/Monad+laws.html
[this one expressed in scala]: http://devth.com/2015/monad-laws-in-scala/
[@dickwall]: https://twitter.com/dickwall
[What have the monads ever done for us]: https://www.youtube.com/watch?v=2IYNPUp751g
[next tick]: https://nodejs.org/docs/latest/api/process.html#process_process_nexttick_callback_arg
