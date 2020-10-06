ARG RUBY_ALPINE_VERSION
FROM ruby:$RUBY_ALPINE_VERSION
ARG RUBY_ALPINE_VERSION
ENV RUBY_ALPINE_VERSION $RUBY_ALPINE_VERSION

# docker build - -t vips-ruby2.3.8 --build-arg RUBY_ALPINE_VERSION=2.3.8-alpine3.8 --build-arg VIPS_VERSION=8.9.2 <vips.ruby.alpine.Dockerfile

# based on felixbuenemann/vips-alpine and codechimpio/vips-alpine
# TODO: also take a look at https://github.com/jcupitt/docker-builds/blob/master/ruby-vips-alpine/Dockerfile
# we don't install from checkouted folder, because we want to test that the gem is available at Rubygems

ARG VIPS_VERSION
ENV VIPS_VERSION $VIPS_VERSION
RUN set -ex -o pipefail && \
    wget -O- https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.gz | tar xzC /tmp && \
    apk update && apk upgrade && apk add --no-cache \
      zlib libxml2 glib-dev gobject-introspection \
      libjpeg-turbo libexif lcms2 fftw libpng \
      orc libgsf openexr && \
    apk add --no-cache --virtual vips-dependencies \
      build-base \
      zlib-dev libxml2-dev gobject-introspection-dev \
      libjpeg-turbo-dev libexif-dev lcms2-dev fftw-dev libpng-dev \
      orc-dev libgsf-dev openexr-dev && \
    cd /tmp/vips-${VIPS_VERSION} && ./configure --prefix=/usr \
                                                --without-python \
                                                --without-gsf \
                                                --without-tiff \
                                                --enable-debug=no \
                                                --disable-static \
                                                --disable-dependency-tracking \
                                                --enable-silent-rules && \
    make -s install-strip && apk del --purge vips-dependencies && \
    cd $OLDPWD && rm -rf /tmp/vips-${VIPS_VERSION}
