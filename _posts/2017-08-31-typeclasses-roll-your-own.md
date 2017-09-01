---
layout: post
title: "Typeclasses? Roll your own!"
categories: learn fp
---

Ever wondered how could your own typeclasses come in handy? This post covers a use case.

Let us begin with an example that looks a lot like the one that I learned from [Juan Manuel Serrano] (that was an excellent workshop, thank you Juan) to showcase a problem which can be solved with parametric polymorphism. However, in my opinion, it smells a bit more realistic - not that much, just a bit.

Given an interface for saving things to some database and load them by id.

```scala
case class User(id: Int, name: String)

trait Database {
  def load(id: Int): User
  def save(user: User): Unit
}
```

And a simple use-case might be something like

```scala
def updateUser(userId: Int, newName: String)(db: Database): User = {
  val user = db.load(userId)
  val updated = user.copy(name = newName)
  db.save(updated)
  updated
}
```

The API is fairly simple, I can provide an in-memory implementation of this for testing very easily.
But what about the implementation used in production? Will it block while interacting with some external database?
We can't let that happen, so we need to change the signatures to return, say `Futures`.

```scala
import scala.concurrent.Future

trait Database {
  def load(id: Int): Future[User]
  def save(user: User): Future[Unit]
}
```

Very well, but now all my implementations, the usages of them, and all my tests need to be updated as well. Also, the tests now became asynchronous and that is bad. In my experience, it is always harder, more inconvenient and error prone.

We can do better! What if we found a way to abstract over the particular type constructor that this trait works with?
So instead of hard coding `Future`, we can use whatever else type constructor we fancy. We can make it a typeclass.

```scala
trait Database[F[_]] {
  def load(id: Int): F[User]
  def save(user: User): F[Unit]
}
```

For testing, we can use a neat little trick: the `Id` type constructor. That way, we are able to provide an implementation __very__ similar to my original stub implementation.

```scala
type Id[T] = T

object FakeDatabase extends Database[Id] {
  def load(id: Int): User = User(id, "testname")
  def save(user: User): Unit = ()
}
```

Now how do we use this? How do we implement the `updateUser` method?
If only there were a way of chaining operations, just like we do with semicolons if no obscure type constructors are in the way. Do this, and then do this, and then return this. Sounds rather imperative, doesn't it?

```scala
trait ImperativeCombinator[F[_]] {
  def doAndThen[A, B](fa: F[A])(f: A => F[B]): F[B]
  def returns[A](a: A): F[A]
}

def updateUser[F[_]](userId: Int, newName: String)(db: Database[F], imp: ImperativeCombinator[F]): F[User] = {
  imp.doAndThen(db.load(userId)) { user =>
    val updated = user.copy(name = newName)
    imp.doAndThen(db.save(updated)) { _ =>
      imp.returns(updated)
    }
  }
}
```

If this `ImperativeCombinator` seems rather familiar it is because it is known as the `Monad` with a slightly different naming convention.
As a side note, maybe this is why our `returns` is called `return` in Haskell?

```scala
trait Monad[F[_]] {
  def flatMap[A, B](fa: F[A])(f: A => F[B]): F[B]
  def pure[A](a: A): F[A] // also known as `point`
}
```

A usage of it would look very familiar to the usage of our `ImperativeCombinator` above.

Passing around all these instances becomes a pain quickly. Fortunately, scala has [implicits]. Without implicits, working with typeclasses would be a rather cumbersome activity. We have to slightly modify the signature and make sure that the appropriate instances are implicitly available in the scope of the invocation.

```scala
def updateUser[F[_]](userId: Int, newName: String)(implicit db: Database[F], monad: Monad[F]): F[User] = {
  monad.flatMap(db.load(userId)) { user =>
    val updated = user.copy(name = newName)
    monad.flatMap(db.save(updated)) { _ =>
      monad.pure(updated)
    }
  }
}

implicit val db: Database[Id] = ???
implicit val monad: Monad[Id] = ???

updateUser[Id](1, "new name")
```

There is a lot of room for improvement here. First things first, let's get rid of the implicit parameters. In scala, one can specify so called [context bounds] to the type parameters with a colon. The following signature effectively means the same as the previous one.

```scala
def updateUser[F[_] : Database : Monad](userId: Int, newName: String): F[User]
```

Much prettier, but now we don't have the instances at hand to use them. We have a number of options here.

The ugly:
```scala
def updateUser[F[_] : Database : Monad](userId: Int, newName: String): F[User] = {
  val db = implicitly[Database[F]]
  val monad = implicitly[Monad[F]]

  // ...
}
```

Also, it is common to provide a companion object to typeclasses with the `apply` to return a particular instance.

```scala
object Database {
  def apply[F[_]]: Database[F] = implicitly[Database[F]]
}

object Monad {
  def apply[F[_]]: Monad[F] = implicitly[Monad[F]]
}

def updateUser[F[_] : Database : Monad](userId: Int, newName: String): F[User] = {
  val db = Database[F]
  val monad = Monad[F]

  // ...
}
```

But let's face it, it is not a huge improvement.

Fortunately, we can apply a trick that makes the usage more convenient. We can provide functions that handle the implicits implicitly.

```scala
object Database {
  object syntax {
    def save[F[_]](user: User)(implicit db: Database[F]): F[Unit] = db.save(user)
    def load[F[_]](id: Int)(implicit db: Database[F]): F[User] = db.load(id)
  }
}

object Monad {
  object syntax {
    def flatMap[F[_], A, B](fa: F[A])(f: A => F[B])(implicit m: Monad[F]): F[B] =
      m.flatMap(fa)(f)

    def pure[F[_], A](a: A)(implicit  m: Monad[F]): F[A] = m.pure(a)
  }
}

import Monad.syntax._
import Database.syntax._

def updateUser[F[_] : Database : Monad](userId: Int, newName: String): F[User] = {
  flatMap(load(userId)) { user =>
    val updated = user.copy(name = newName)
    flatMap(save(updated)) { _ =>
      pure(updated)
    }
  }
}
```

Please note, that in the end of our algorithm we are really just `map`-ping the `Unit` returned from `save` to `User`. Since `Monads` are also `Functors` they should have that `map` operation anyway, and, as our usage shows, it can be derived from `flatMap` and `pure`.

```scala
trait Monad[F[_]] {
  // ...
  def map[A, B](fa: F[A])(f: A => B): F[B] = flatMap(fa)(f andThen pure)
}

object Monad {
  object syntax {
    // ...
    def map[F[_], A, B](fa: F[A])(f: A => B)(implicit m: Monad[F]): F[B] = m.map(fa)(f)
  }
}

import Monad.syntax._
import Database.syntax._

def updateUser[F[_] : Database : Monad](userId: Int, newName: String): F[User] = {
  flatMap(load(userId)) { user =>
    val updated = user.copy(name = newName)
    map(save(updated))(_ => updated)
  }
}
```

Of course, this syntax is not very convenient, using infix operators would be much better:

```scala
def updateUser[F[_] : Database : Monad](userId: Int, newName: String): F[User] = {
  load(userId) flatMap { user =>
    val updated = user.copy(name = newName)
    save(updated) map { _ => updated}
  }
}
```

It is almost effortlessly achievable, it only requires some class, that has this kind of `flatMap` on it, and an implicit conversion in scope from `F` to this class.
We could do this by defining the class, and then an implicit function to do the conversion, or we could just do it in one step.

Say hello to implicit classes.

```scala
object Monad {
  object syntax {
    implicit class MonadOps[F[_], A](fa: F[A])(implicit m: Monad[F]) {
      def flatMap[B](f: A => F[B]) = m.flatMap(fa)(f)
      def map[B](f: A => B) = m.map(fa)(f)
    }
  }
}
```

Aaaaaand, given we have something that has `flatMap` and `map` on it, we could even write our logic as a `for` comprehension, which is basically just syntactic sugar for a series of `flatMaps` and `maps` ([and others]).

```scala
def updateUser[F[_] : Database : Monad](userId: Int, newName: String): F[User] = for {
  user <- load(userId)
  updated = user.copy(name = newName)
  _ <- save(updated)
} yield updated
```

Now that's much nicer in my opinion.
> Note how much it resembles our original imperative implementation, but now we have the superpower to abstract over even more details than we could at first. Separate the logic from the interpretation and, if you ask me, that is huge.

Of course, you don't have to roll your own `Monad` typeclass, the syntactic sugar for it, nor the `Id` type constructor and its `Monad` instance. You could use [cats] or [scalaz] instead. They also come with a lot of other typeclasses, and instances for them as well.
The following is the complete code example using cats with the minimally necessary imports.

```scala
import cats.Id
import cats.Monad
import cats.syntax.flatMap._
import cats.syntax.functor._

case class User(id: Int, name: String)

trait Database[F[_]] {
  def load(id: Int): F[User]
  def save(user: User): F[Unit]
}
object Database {
  object syntax {
    def save[F[_]](user: User)(implicit db: Database[F]): F[Unit] = db.save(user)
    def load[F[_]](id: Int)(implicit db: Database[F]): F[User] = db.load(id)
  }

  // We can provide some instances in the companion object, if we like
  implicit val dbId = new Database[Id] {
    def load(id: Int): User = User(id, "some name")
    def save(user: User): Unit = ()
  }
}

import Database.syntax._

def updateUser[F[_] : Database : Monad](userId: Int, newName: String): F[User] = {
  for {
    user <- load(userId)
    updated = user.copy(name = newName)
    _ <- save(user.copy(name = newName))
  } yield updated
}

assert(updateUser[Id](1, "some other name") == User(1, "some other name"))
```

One serious problem remains, though. What about errors? What if the user could not be found, or the connection to the database is lost for example.
We shall see it in the next post, which will be about a typeclass called `MonadError`.

[Juan Manuel Serrano]: https://github.com/jserranohidalgo
[implicits]: https://docs.scala-lang.org/tour/implicit-parameters.html
[context bounds]: https://docs.scala-lang.org/tutorials/FAQ/context-bounds.html
[and others]: https://docs.scala-lang.org/tutorials/FAQ/yield.html
[cats]: https://typelevel.org/cats/
[scalaz]: https://github.com/scalaz/scalaz


