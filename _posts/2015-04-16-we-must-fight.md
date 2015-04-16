---
layout: post
title: "We must fight until only one remains."
date: 2015-04-16
categories: fun
---
## Brief intro
We chose to have [ElasticSearch] for our wall posts as a primary database. It deserves its own post, but that's not the point here.
Due to different events, the users should see automatic posts, such as

> User A uploaded n photos to Album B

Yes, we are working on a social site... in 2015... I know. At least we can always check how facebook does the things :)

## The thing
Due to a design flaw on my side, concurrency, and the __near__ realtime nature of ElasticSearch there were duplications.

We had already written a method finding all matching posts, and wrote the one that clears the results, leaving only one behind.
We were struggling to name the method, which wraps the two. Its job is to load 0 or 1 existing post. If the finder finds more than one, it should call the clearer method.

## Outcome
After a few minutes, we found the perfect name: `mcLoadPost`. Boy, it was a cheerful afternoon.
It was a few days ago, I'm still laughing.

Code smell?

[ElasticSearch]: https://www.elastic.co/
