ARG RUBY_VERSION
ARG ALPINE_VERSION
FROM ruby:${RUBY_VERSION}-alpine${ALPINE_VERSION}

RUN apk add --no-cache git build-base
RUN git clone https://github.com/Nakilon/dhash-vips.git --depth 1 --branch alpine-compilation-issues

ARG RUBY_VERSION
RUN mkdir /ruby && set -ex -o pipefail && wget -O- https://cache.ruby-lang.org/pub/ruby/ruby-${RUBY_VERSION}.tar.gz | tar xzC /ruby --strip-components=1

RUN cd dhash-vips && ruby extconf.rb && make


# docker build - -t temp-ruby2.3.8 --build-arg RUBY_VERSION=2.3.8 --build-arg ALPINE_VERSION=3.8 <Dockerfile
# docker build - -t temp-ruby2.4.10 --build-arg RUBY_VERSION=2.4.10 --build-arg ALPINE_VERSION=3.11 <Dockerfile
# docker build - -t temp-ruby2.5.8 --build-arg RUBY_VERSION=2.5.8 --build-arg ALPINE_VERSION=3.12 <Dockerfile
