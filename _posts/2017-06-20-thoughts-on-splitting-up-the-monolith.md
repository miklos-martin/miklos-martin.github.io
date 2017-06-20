---
layout: post
title: "Thoughts on splitting up the monolith"
categories: msa
---

I was attending [CraftConf] this year. Although last year's schedule was more densely packed with microservices based talks, we weren't short of them this year either. And that's fine. There is one thing that bothers me about monolith-to-microservices talks though.

This very figure:

![monolith to microservices][monolith to msa]
<small><i>Figure 1. The standard monolith to microservices illustration</i></small>

### What does that imply?

> Your monolithic, legacy codebase embodies decades of accumulated wisdom which manifests in carefully crafted modules with clear and ruthlessly enforced boundaries, implemented in a disciplined manner, packed with loads of unit-, integration- and end-to-end tests.

Is that the case?

Is your legacy code robust, yet flexible, modular, easy to modify, or even - god forbid - easy to throw out and replace? Is it?

Do you imagine something like a soft block of clay when you think about your code? Does carving out pieces, and implementing them with microservices - using whatever stack and tooling is ~~fancy right now~~ the best suited - sound like a breeze?

I really don't know much about the real-world legacy apps out there, but I have a gut feeling that if you are seriously slowed down by your code, down to an extent that you are willingly let the architectural, operational, organizational and overall complexity of microservices take on your team(s), that's likely not the case.
Based on my experience, doing this work is certainly a challenge. The process deserves much more than a figure like the one shown above.

### MVP and technical debt

We've all developed, seen or at least heard about apps hacked together with ruby on rails or some php framework in the spirit of the MVP and putting time to market above all.
I bet the transition in case of these apps could be illustrated more accurately with this:

![the jenga tower method][jenga tower method]
<small><i>Figure 2. The jenga tower method</i></small>

The splitting may work out pretty well to some extent, then a sudden wrong move and ... BOOM!

Or worse, what do you do to decompose something like this:

![decomposing a balloon][decomposing a balloon]
<small><i>Figure 3. Decomposing a balloon</i></small>

Of course, these are exaggerating illustrations, but still: how do you approach situations like these? That's what I'd rather see a talk about.

Dear speakers, please do give a talk on the process itself, the challenges, the tips and tricks, on how did you __actually__ tackle the problem. Let us hear more about war stories instead of idealistic, simplified scenarios. Thank you!

[CraftConf]: https://craft-conf.com
[jenga]: https://en.wikipedia.org/wiki/Jenga
[monolith to msa]: /images/splitting-up-the-monolith/monolith-to-microservices.jpg
[jenga tower method]: /images/splitting-up-the-monolith/jenga-tower-method.jpg
[decomposing a balloon]: /images/splitting-up-the-monolith/decomposing-a-balloon.jpg
