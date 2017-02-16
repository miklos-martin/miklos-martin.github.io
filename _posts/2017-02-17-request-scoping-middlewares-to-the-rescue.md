---
layout: post
title: Request scoping, middlewares to the rescue
categories: node
---
# The problem

Currently, we are working on our second project with a REST-ish backend API and a node.js frontend.
During the development of the previous one, it was a major pain point to ensure that all the requests made to the backends include the appropriate information from the original request, such as the user's original IP, or the correct correlation id and so on. And it would have been super-nice to collect debug information and visualize it on a debug panel during development, but it was basically impossible.

That was because a general module was built to actually do the communication with the APIs over HTTP, which was completely unaware of the original request.

We had something like this in a module:

{% highlight javascript %}
// lib/request.js
const https = require('https')

module.exports = {
  get: ...,
  post: ...,
  put: ...,
  patch: ...,
  delete: ...
}
{% endhighlight %}

And we used it like this from different services:

{% highlight javascript %}
// services/user.js
const request = require('../lib/request')

module.exports = {
  findUserById: id => request.get('URL of user')
}
{% endhighlight %}

And, finally, a controller was similar to this:

{% highlight javascript %}
// controllers/user/show.js
const userService = require('../../services/user')

module.exports = (req, res, next) => {
  userService.findUserById(req.id)
    .then(user => res.render('user/show', user))
    .catch(next)
}
{% endhighlight %}
This might seem kind of OK, but it is not. For testing those services you either use [some tool which can mock out http calls] or some [other nasty stuff]. When you need to pass along something from the original request, then you have to pass this information around, through all those "layers".
By the time we realized the need, it was too late. It would have been very uncomfortable even if node had something similar to scala's implicits.
So what we did was not the solution I am proud of, and not the one that is bug free either. We hacked in here and there a few things, and made it work, well, most of the time. But continued to observe backend requests that weren't ornamented properly.

It was bad.

It was the bad thing to do.

# What now?

This time we knew better. 

This decision was among the first ones we made. We had a feeling that we need to put this communication thing somehow in a middleware but was unsure about the exact _how_.

I had the idea to make those functions - which make the API calls - pure: they should just describe the _what_, not he _how_ and they definitely shouldn't do any I/O. That sounds fine, but how do you actually implement something like that, how do you do the actual HTTP call in the next middleware and complete your promises?
I discussed my ideas and problems with [@fsticza], a dear colleague of mine, and he asked 

> "Do you mean the services would return functions which would take the concrete fetcher function as an argument?"
>
> "Not exactly, but hey, you know what? That's even better!"

So we came up with something like the following

{% highlight javascript %}
// app/user/service.js
module.exports = {
  findUserById: id => fetch => fetch('URL of user')
}
{% endhighlight %}

In a controller

{% highlight javascript %}
// app/user/show.js
const userService = require('./service')

module.exports = (req, res, next) => {
  userService.findUserById(req.id)(req.fetch)
    .then(user => res.render('user/show', user))
    .catch(next)
}
{% endhighlight %}

And where does that req.fetch comes from?

{% highlight javascript %}
// app/middlewares/fetch.js
module.exports = (req, res, next) => {
  req.fetch = (uri, options = {}) => ...
  next()
}
{% endhighlight %}

# Benefits

This allows us to adjust the request options (e.g. headers) or collect debug information from the backend requests we made, log it if necessary, and include it in the response in debug mode - in a centralized way.
We could single-handedly draw a timeline of the requests we made for example. This is a major win, we can clearly see now how those requests were laid out in time, easily identify the ones which could have been sent concurrently for example.
Also, we could include profiler links for each one - which are provided by the [framework] we use on the backends - to easily access additional details about a given request, such as database queries, cache stats, lucene search queries and so on. 

Last but not least another huge benefit, that our services are now easily testable, no need for hackish solutions.

Thanks to [@fsticza] and [@hello-brsd] for their feedback on the draft of this post.


[some tool which can mock out http calls]: https://github.com/node-nock/nock
[other nasty stuff]: https://github.com/jhnns/rewire 
[@fsticza]: https://github.com/fsticza
[framework]: https://symfony.com
[@hello-brsd]: https://github.com/hello-brsd
