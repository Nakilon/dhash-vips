FROM ruby:2.6-alpine

# based on felixbuenemann/vips-alpine and codechimpio/vips-alpine
# TODO: also take a look at https://github.com/jcupitt/docker-builds/blob/master/ruby-vips-alpine/Dockerfile

ARG VIPS_VERSION=8.9.2
ARG DHASH_VIPS_VERSION

RUN set -ex -o pipefail && \
    wget -O- https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.gz | tar xzC /tmp && \
    apk update && apk upgrade && apk add --no-cache \
      zlib libxml2 glib-dev gobject-introspection \
      libjpeg-turbo libexif lcms2 fftw libpng \
      orc libgsf openexr && \
    apk add --no-cache --virtual vips-dependencies build-base \
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
    make -s install-strip && cd $OLDPWD && rm -rf /tmp/vips-${VIPS_VERSION} && \
    apk del --purge vips-dependencies && \
    apk add --no-cache --virtual ffi-dependencies build-base libffi-dev && gem install dhash-vips -v $DHASH_VIPS_VERSION && apk del --purge ffi-dependencies
# we don't install from checkouted folder, because we want to test that the gem is available at Rubygems
