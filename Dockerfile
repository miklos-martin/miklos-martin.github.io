FROM debian:wheezy

RUN apt-get update && apt-get install -y aspell

VOLUME /blog
WORKDIR /blog

CMD spell/check.sh