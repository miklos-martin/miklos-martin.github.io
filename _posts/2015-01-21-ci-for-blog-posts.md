---
layout: post
title: "CI for blog posts"
date: 2015-01-21
categories: tips ci
---

I've recently read a post about [how GitHub writes blog posts][github posts]. They are running some tests (!) on the posts. Fascinating.

I've immediately decided to implement it here, on my own blog.
The author provided a [gist] of what they are using. I'm not a Ruby guy, and I'm afraid I'm missing some fundamental knowledge about gems and bundler and stuff. But I did my best. Didn't work. So I had a closer look at what it is doing, to see if I can implement its features in another way quickly, or if I can live without them.

### The things it does

#### Image alt tags
OK, it's nice, push it down in the backlog.

#### Image size
I don't really care right now, maybe later.

#### Image promotions
Come on! This blog will barely contain 5 images anyway. 
I don't need it.

#### CDN hosted images
The whole site is hosted on a CDN. 
I don't need it.

#### No emoji
I agree, but it wouldn't come to my mind to insert one either. 
I don't need it.

#### No "Today, "
Well, it doesn't seem that important, does it?
I don't need it.

So I could strike through the whole list and started to think of...

### What do I need exactly?

Spell check.

English is my second language, and I'm not nearly as good at speaking or writing it as I want to be. Spell check would be nice.

Google told me there is a command line utility called [Aspell]. It is very nice, by the way, I was impressed. It can do it's job in multiple languages, can use custom dictionaries, and shipped with my distro by default.

So I wrote a little [shell script][spell check] and put a [.travis.yml][travis] together, and voilà, I have _Continuous Integration for my blog posts_.

How cool is that? I should have thought about it by myself.

I'm planning to add
- grammar check
- broken links check
- image alt tags and size checks after I've added at least one image

So there are a number of things that has yet to be done, but I'm fine with this setup for now.

Thank you, GitHub and Zach Holman.

[github posts]: http://zachholman.com/posts/how-github-writes-blog-posts/
[gist]: https://gist.github.com/holman/4bd27ba3950ee2ee79c3
[Aspell]: http://aspell.net/
[spell check]: https://github.com/miklos-martin/miklos-martin.github.io/blob/master/spell/check.sh
[travis]: https://github.com/miklos-martin/miklos-martin.github.io/blob/master/.travis.yml 
