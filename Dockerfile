ARG RUBY_ALPINE_VERSION
FROM ruby:$RUBY_ALPINE_VERSION
ARG RUBY_ALPINE_VERSION
ENV RUBY_ALPINE_VERSION $RUBY_ALPINE_VERSION

RUN apk add --no-cache git build-base && \
    git clone https://github.com/Nakilon/dhash-vips.git --depth 1 --branch alpine-compilation-issues

ARG RUBY_TAG
RUN git clone https://github.com/ruby/ruby.git --depth 1 --branch $RUBY_TAG

RUN cd dhash-vips && bundle install --no-cache && ruby extconf.rb && make


# docker build - -t temp-ruby2.3.8 --build-arg RUBY_ALPINE_VERSION=2.3.8-alpine3.8 --build-arg RUBY_TAG=v2_3_8 <Dockerfile
