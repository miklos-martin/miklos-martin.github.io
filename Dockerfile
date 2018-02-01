FROM debian:wheezy

RUN apt-get update && apt-get install -y aspell

VOLUME /blog
WORKDIR /blog

ENV LANG=C.UTF-8

CMD spell/check.sh