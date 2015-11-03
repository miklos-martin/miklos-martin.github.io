---
layout: post
---
## NO belief

You want to be serious. You want to be precise. You want your words to be actually worth something. You want to influence your environment. You want to have impact. You want to be a trusted and proven craftsman.

You don't just trust random blog posts or any other source of knowledge when dealing with a new technology, or even just with a new third-party lib for example.
Don't get me wrong, these sources are extremely helpful. They can give you hints and ideas, share some experience with you. But no matter how sweet it sounds, you always want to try it out for yourself: check how it behaves during high load, try edge cases and so on.
You can not be truly prepared otherwise. Still, you can definitely face problems later. At least your conscience will be clear. You did everything you could prior the decision at hand and now you also have more experience with the edge cases you validated, so you can narrow the problem-space down and find the root cause and the solution more quickly and more confidently.

![No, no, Mr. gullible no es here][nono]

__Documentation is key!__ You absolutely need to back your decesions on these kind of things with documenting your experiences. It will be extremely helpful if you are not the one who faces the aforementioned problems later - especially if they show up in production. And of course, it can come in handy for you as well. You don't neccessarly need extensive documentation, it could be enough to link resources which were found useful, and note the gotchas. Just have something that you and your fellow engineers can turn to and learn from. That documentation can be used to reproduce the things you did, because others coming after you might also want to try it out for themselves.

TIP: the readme of your repository is a good-enough place for this kind of stuff.

### E.G.

Take [docker] for example. The internet is full with 'docker is awesome' stuff. And it's simply not true.
They added syslog support in the 1.6 release. No kidding: 1.6. Before that, you couldn't do proper logging, because it was impossible to rotate the container log files without restarting them. Well you could work around it, of course, you had to mount a logfile from the host machine, but that was kind of odd and less convenient than just writing everything on stdout.

_Did you use it in production?_

We launched two instances of an AMI. These machines were completely identical. On could serve requests, the other couldn't. How is that possible?
Going deeper it turned out that docker on the problematic machine messed up resolve confs of the containers and they couldn't communicate with each other, or the outside world.

_Did you use it on your dev-machine?_

In combination with docker compose - formerly known as fig - it can be a powerful tool, I must say. I can simulate n-machine environments on my single laptop, I can "copy" any of our production servers of any of our projects without messing up my laptop completely. But all that power comes with a price. A price paid in time. If you have to rebuild your containers, or even just restart them all, it takes time. It takes surprisingly long time to shut them all down (maybe I made some horrible mistakes that I haven't realised yet).

There is something which is true for every learning process: you slow down first to be able to go more quickly afterwards than you ever could before. I have a feeling that I've wasted a lot more time on issues like these with docker that could have been acceptable, and I don't really feel it is worth it yet.

So now I would rather say: Hello docker, welcome on my laptop, but stay away from my production servers!

## NO blame

At first, I thought something like: 'I wish someone else had written this software, it would be so much more easy to blame someone else for these faults!' - wrong.
It turned out, at least for me, it was far easier to correct my own mistakes, and even others' too when I didn't take time to blame the original author, or the decisions that led to those faulty implementations. I could focus on a solution, and could deliver it more quickly. As a team, we could deliver positive results more quickly. We re-gained our client's trust, and our own trust in the software itself. And that's quite important IMHO.
I will never `git blame` anything again just to find out who committed the crime at hand.

##

[nono]: https://i.imgflip.com/rvbha.jpg
[docker]: https://www.docker.com/
