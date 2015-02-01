---
layout: post
title: "How to spend a few hours with a 5 minute configuration task"
date: 2015-01-29
categories: wasting time
---
I needed to add Cross-Origin Resource Sharing - a.k.a. CORS - support to a server. OK, I've already heard of it, I just set some `Access-Control-Whatever` headers and I'm done. 5 minutes.

The server is running nginx, and php-fpm to serve a PHP application. I thought I won't bother with these settings in the application code, I can do this in the nginx config.
I fired up google, searched for it a bit, and almost immediately found what I needed: [this example configuration][cors-nginx]

There are way too much comments in the example, tl;dr.
The important things to note:

1. it checks for a given origin to enable CORS for just that domain,
2. does some nasty string-concatenating hacks because of the lack of nested if support in nginx config files
3. sets some `Access-Control-Whatever` headers, the ones I needed
4. states at the end: `# --PUT YOUR REGULAR NGINX CODE HERE--`

The related part of my original configuration looked like this:

<pre>
location / {
    index index.php;
    try_files $uri /index.php?$args
}
</pre>

I'm not going to insert here what happened after I copied and pasted that huge example. I just modified the relevant parts, changed the regex to match the correct domain, added some extra headers and stuff.

The `OPTIONS` request went well... well, not so well at first, that was the point I included some extra allowed headers. But afterwards my application has stopped working. After a while I figured out that the problem occurred if the `Origin` header was set, and matched the regex specified at the beginning.
I got `404` for every request.

WTF?

It was just some innocent `if`-s and headers.

It was weird. The logs said there was no file named `/whatever/path/my/request/matched/index.php`. I didn't know at first, but slowly, after a vast amount of time, I realized that `try_files` just stopped working. I tried a lot of different approaches to achieve my goal, but the problem has remained. WTF? What causes this behavior? In the end, there were nothing extra in my config compared to the initial one, just an if statement with an empty body.

Then I found this article: [if is evil]. Just the related part from the weird bugs section:

<pre>
# try_files wont work due to if
location /if-try-files {
     try_files  /file  @fallback;

     set $true 1;

     if ($true) {
         # nothing
     }
}
</pre>

Indeed.

Dear reader, if you are about to write any if statements in you nginx configuration, I kindly suggest you to read those gotchas. I was surprised.

By the way, I ended up removing all the `if`-s, except one: the check for `OPTIONS` request method. I left that in, because it returns with a `204` response and I don't need the `try_files` afterwards. I put `Access-Control-Allow-Origin` and `Access-Control-Allow-Credentials` headers on every response. It works, but I don't like it. It's just a test server behind a firewall anyway, I will figure out something more elegant for production.

Another note for first-timers: check your actual pre-flight `OPTIONS` requests to see what headers, methods etc do you need exactly.


[cors-nginx]: http://enable-cors.org/server_nginx.html
[if is evil]: http://wiki.nginx.org/IfIsEvil
