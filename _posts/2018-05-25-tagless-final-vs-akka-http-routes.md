---
layout: post
title: "Tagless final vs. akka-http routes"
categories: tips
---

Have you ever wondered how could you set up some akka-http routes for your tagless final program? Did you end up hardcoding your concrete `F[_]` to something `ToResponseMarshallable` in order to build your routes? I have. I did. Not anymore!

# The problem

It turns out I have already written bits about tagless final [here] and [there], I just didn't know it's called that then.
I think we can dig up that little example from those posts.

```scala
trait Database[F[_]] {
  def load(id: Int): F[User]
  def save(user: User): F[Unit]
}
```

Now assume we want to provide an HTTP endpoint for loading users by id. Also assume that we can effortlessly convert case classes to JSON so we don't have to deal with it now. Something like this:

```scala
def route[F[_] : Database] = get {
  path("users" / IntNumber) { id =>
    complete(Database[F].load(id))
  }
}
```

The only problem with this is that it won't compile (and not just because of the missing imports from the snippet).

```
Type mismatch, expected: ToResponseMarshallable, actual: F[User]
```

Note that the final type of that will likely be something like `Future[User]`, or in tests maybe `Try[User]` or `Id[User]`, all of which should be totally marshalled out of the box. Had we used a concrete type instead of `F[_]` it would have worked. But it is advisable to avoid that in the hope that low-level details like this will not pollute our code where it is not necessary.

The question is, how do we persuade the compiler that this is going to be fine? Googling around led me to [this discussion], where this problem is solved, but it is a bit clunky for my taste. After fiddling around with it, I ended up with the following.

# A way of doing this

What is needed is something that has the ability to provide a `ToResponseMarshaller[F[A]]` for all `A` where `A` itself also has a `ToResponseMarshaller` instance.
That smells awfully like yet another typeclass for our `F[_]`-s.

```scala
trait Marshallable[F[_]] {
  def marshaller[A : ToResponseMarshaller]: ToResponseMarshaller[F[A]]
}
```

A convenient place to provide instances for this is in the companion object. We also need to have something that will bring these `ToResponseMarshaller`-s in scope implicitly when needed. The companion is a great place for this implicit function too.

```scala
object Marshallable {
  implicit def marshaller[F[_], A : ToResponseMarshaller](implicit M: Marshallable[F]) =
    M.marshaller

  implicit val futureMarshaller = new Marshallable[Future] {
    def marshaller[A: ToResponseMarshaller] = implicitly
  }

  implicit val tryMarshaller = new Marshallable[Try] {
    def marshaller[A: ToResponseMarshaller] = implicitly
  }
}
```

Note, that we don't need to reimplement those `ToResponseMarshaller`s which are already present in akka-http, we can use them `implicitly`. How very nice!

Now we only need to put the `Marshallable` constraint on our `F[_]` and bring the implicit function into scope, then it clicks.

```scala
import Marshallable._

def route[F[_] : Database : Marshallable] = get {
  path("users" / IntNumber) { id =>
    complete(Database[F].load(id))
  }
}
```

I like the elegance of it very much. If only I could get rid of the `import Marshallable._` part somehow, that would be a huge improvement.


[here]: /learn/fp/2017/08/31/typeclasses-roll-your-own.html
[there]: /learn/fp/2017/09/28/handling-monadic-errors.html
[this discussion]: https://groups.google.com/forum/#!topic/akka-user/K9Hfcq7EDQI
