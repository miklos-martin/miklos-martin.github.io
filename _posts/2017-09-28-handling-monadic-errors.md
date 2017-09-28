---
layout: post
title: "Handling monadic errors"
categories: learn fp
---

In the [last post] we have seen how our very own typeclasses can come in handy, and how we can use them in combination with Monads.
I will assume you have read that.

In this post, we will explore the options of error handling during monadic computations.

## Motivation

Our API was

```scala
trait Database[F[_]] {
  def load(id: Int): F[User]
  def save(user: User): F[Unit]
}

object Database {
  object syntax {
    def save[F[_]](user: User)(implicit db: Database[F]): F[Unit] = db.save(user)
    def load[F[_]](id: Int)(implicit db: Database[F]): F[User] = db.load(id)
  }
}
```

We can implement an instance for any type constructor, and the problem is we know nothing here about errors. The different type constructors have different ways to approach errors, or none at all. Think about how different it is to deal with a failed `Future` from dealing with a `Left` for example. What can we do about it?

One way, is to use `Either`, for example. Note, that in this post we are not abstracting over the type which represents the failure for the sake of simplicity, we will just stick with `Throwable`.

```scala
trait Database[F[_]] {
  def load(id: Int): F[Either[Throwable, User]]
  def save(user: User): F[Either[Throwable, Unit]]
}

object Database {
  object syntax {
    def load[F[_]](id: Int)(implicit db: Database[F]): F[Either[Throwable, User]] = db.load(id)
    def save[F[_]](user: User)(implicit db: Database[F]): F[Either[Throwable, Unit]] = db.save(user)
  }
}
```

It is obviously more complex, but at least we have a unified way to deal with errors. 

```scala
import cats.Monad
import cats.syntax.flatMap._
import cats.syntax.functor._
import Database.syntax._

def updateUser[F[_] : Database : Monad](userId: Int, newName: String): F[Either[Throwable, User]] =
  load(userId) flatMap {
    case Right(user) =>
      val updated = user.copy(name = newName)
      save(updated) map {
        case Right(_) => Right(updated)
        case Left(e) => Left(e)
      }
    case left => Monad[F].pure(left)
  }
```

Cumbersome, yes, not only dealing with errors, but accessing the successfully computed values became more complex. 
The `EitherT` monad transformer helps, but it is still not very convenient.

```scala
import cats.data.EitherT

trait Database[F[_]] {
  def load(id: Int): EitherT[F, Throwable, User]
  def save(user: User): EitherT[F, Throwable, Unit]
}

object Database {
  object syntax {
    def load[F[_]](id: Int)(implicit db: Database[F]): EitherT[F, Throwable, User] = db.load(id)
    def save[F[_]](user: User)(implicit db: Database[F]): EitherT[F, Throwable, Unit] = db.save(user)
  }
}

import cats.Monad
import Database.syntax._

def updateUser[F[_] : Database : Monad](userId: Int, newName: String): EitherT[F, Throwable, User] = for {
  user <- load(userId)
  updated = user.copy(name = newName)
  _ <- save(updated)
} yield updated
```

This seems quite OK, but one have to deal with certain issues.

One of them are the type signatures: they've grown unbearably ugly and harder to understand. Simpler types __do__ matter, especially when you try to reason about your code.

Now imagine your type constructor is a `Future`. Not only Futures are very capable of representing erroneous computations on their own, but now you have to **always recover them** with a `Left` inside.

Of course, you could do something like:

```scala
implicit class FutureConverter[T](future: Future[T]) {
  def toEitherT: EitherT[Future, Throwable, T] = EitherT {
    future
      .map(Right.apply)
      .recoverWith {
        case e: Throwable => Future.successful(Left(e))
      }
  }
}
```

Then you could call `.toEitherT` on any Future you like as long as this implicit class is in scope.
But it does not solve the problems, you would still have type signatures that are hard to grasp and you would still be forced to do these conversions.

Conversations about code like this become tricky very quickly.

> "So, could you tell me how do you think we should implement this function that returns the followers of the user?"
> 
> "Sure, it shouldn't be hard. You take this thing here, it's basically just a Future of Either a Throwable or a User, but we use this EitherT transformer to make things easier, you see. So just grab the user if it's in there, and you can pass it in this other function, which returns a Future of Either a Throwable or a List of Users. Oh, and don't forget to wrap that Future in EitherT! Lucky for you, we have this bit of implicit magic, just import this FutureConverter and you can call .toEitherT on Futures. Cool, huh?"
> 
> "Yeah, but, umm... how was that Future of List of Eithers of that T or what again?"

## Fear not, there is a way out!

There is a typeclass, called `ApplicativeError`. This extends `Applicative` with capabilities for dealing with errors. The two main functions are `raiseError` and `handleErrorWith`. The first is like `pure`, but for errors, it lifts an error value to the context of `F`. The latter is responsible for handling errors, potentially recovering from it.

Here are their signatures:

```scala
trait ApplicativeError[F[_], E] extends Applicative[F] {
  def raiseError[A](e: E): F[A]
  def handleErrorWith[A](fa: F[A])(f: E => F[A]): F[A]
}
```

A bunch of other - rather useful - functions can be derived from these and others on `Applicative`, like `handleError`, which is to `handleErrorWith` like `map` is to `flatMap`, or `recover` and `recoverWith` which are probably familiar from `Future`, they do the same: attempt to recover with the supplied `PartialFunction[E, A]` or `PartialFunction[E, F[A]]` respectively.

Now we can finally meet the goal of this post:

```scala
trait MonadError[F[_], E] extends ApplicativeError[F, E] with Monad[F] {
  // ...
}
```

`MonadError` holds the promise of simpler type signatures, since we no longer need to explicitly rely on `Either` or any other wrapper around our types, instead, we require our type constructors to be members of this typeclass too.

```scala
trait Database[F[_]] {
  def load(id: Int): F[User]
  def save(user: User): F[Unit]
}
object Database {
  object syntax {
    def save[F[_]](user: User)(implicit db: Database[F]): F[Unit] = db.save(user)
    def load[F[_]](id: Int)(implicit db: Database[F]): F[User] = db.load(id)
  }
}

import cats.MonadError
import cats.syntax.flatMap._
import cats.syntax.functor._
import cats.syntax.applicativeError._
import Database.syntax._

def updateWithLog[F[_] : Database](userId: Int, newName: String)(implicit me: MonadError[F, Throwable]): F[User] =
  updateUser(1, "John")
    .map { updated =>
      println("success")
      updated
    }
    .recoverWith { case error =>
      println(error)
      me.raiseError(error)
    }

def updateUser[F[_] : Database](userId: Int, newName: String)(implicit me: MonadError[F, Throwable]): F[User] = for {
  user <- load(userId)
  updated = user.copy(name = newName)
  _ <- save(updated)
} yield updated
```

Note what we return from the `Database`, it is just an `F[User]` which can be perfectly used as a `Monad` alone, a non-nested, transformer-free simple `Monad`. Which also happens to know about errors, so if we use this with a `Future` as `F`, then no additional recovery steps are necessary.

For those who worry about the current signature of `updateUser`, it is extremely unlikely that we want to use the functions provided by the typeclass with mixed type constructors in the same scope, so we can safely move our type parameters and implicit evidences to a class constructor for example.

```scala
class UserStuff[F[_] : Database](implicit me: MonadError[F, Throwable]) {
  import cats.syntax.flatMap._
  import cats.syntax.functor._
  import Database.syntax._

  def updateUser(userId: Int, newName: String): F[User] = for {
    user <- load(userId)
    updated = user.copy(name = newName)
    _ <- save(updated)
  } yield updated
}
```

We can make this even more concise and nicer with the use of the [kind projector compiler plugin].

````scala
class UserStuff[F[_] : Database : MonadError[?, Throwable]] {
  import cats.syntax.flatMap._
  import cats.syntax.functor._
  import Database.syntax._

  def updateUser(userId: Int, newName: String): F[User] = for {
    user <- load(userId)
    updated = user.copy(name = newName)
    _ <- save(updated)
  } yield updated
}
```

But what happens to `Id`, you may ask. Well, `Id` is gone. We can no longer use it in our synchronous implementation for testing, we either have to swap that one out for something binary, a data type that can handle two cases, say, an `Either` or a `Try`, or, as [@jserranohidalgo] pointed out, something lazy as `Eval`[^1] or even `Unit => ?`[^2]. But that's OK, it is far less pain then the complexity and the transformations before.

And, to use some more implicit magic, we can do something cool.

```scala
import cats.syntax.applicativeError._
import cats.syntax.flatMap._

implicit class LogOps[F[_], A](fa: F[A])(implicit me: MonadError[F, Throwable]) {
  def logFailure(msg: Throwable => String): F[A] = fa recoverWith {
    case e: Throwable =>
      println(msg(e))
      fa
  }

  def logInfo(msg: A => String): F[A] = fa flatMap { value =>
    println(msg(value))
    fa
  }
}
```

With this one in scope, we can always do things like the following:

```scala
updateUser(1, "John")
  .logFailure(e => s"Aw, snap! Failed to update user, because of $e")
  .logInfo(u => s"Successfully updated user: $u")
```

So, whenever you find yourself wrapping your types with `Either` or `Try` in parameterized type constructors just to deal with errors, I strongly encourage you try `MonadError` instead. It's just so much simpler to deal with.

[last post]: /learn/fp/2017/08/31/typeclasses-roll-your-own.html
[kind projector compiler plugin]: https://github.com/non/kind-projector
[@jserranohidalgo]: https://github.com/jserranohidalgo
[^1]: See [an implementation for `Eval` here]
[^2]: I wanted to provide an implementation in this post, but I haven't figured out one yet that obeys all laws. I keep failing [this one]. Probably I will publish that in a separate post once I get that right.
[an implementation for `Eval` here]: https://github.com/atnos-org/eff/blob/master/shared/src/main/scala/org/atnos/eff/EvalEffect.scala#L73
[this one]: https://github.com/typelevel/cats/blob/master/laws/src/main/scala/cats/laws/MonadErrorLaws.scala#L8
