ARG RUBY_ALPINE_VERSION
FROM ruby:$RUBY_ALPINE_VERSION
ARG RUBY_ALPINE_VERSION
ENV RUBY_ALPINE_VERSION $RUBY_ALPINE_VERSION

# docker build - -t image1-ruby2.3.8 --build-arg RUBY_ALPINE_VERSION=2.3.8-alpine3.8 <image1.Dockerfile

RUN set -ex && \
    apk update && apk upgrade && apk add --no-cache \
      zlib libxml2 glib-dev gobject-introspection \
      libjpeg-turbo libexif lcms2 fftw libpng \
      orc libgsf openexr
