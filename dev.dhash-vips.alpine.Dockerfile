ARG VIPS_DOCKER_IMAGE
FROM $VIPS_DOCKER_IMAGE

# docker build - -t dev-v0.1.1.2-dhash-vips-ruby2.3.8 --build-arg VIPS_DOCKER_IMAGE=vips-ruby2.3.8 --build-arg RUBY_TAG=v2_3_8 --build-arg DHASH_VIPS_TAG=v0.1.1.2 <dev.dhash-vips.alpine.Dockerfile
# docker run --rm -v $(pwd)/benchmark_images:/images -w /dhash-vips dev-v0.1.1.2-dhash-vips-ruby2.3.8 bundle exec rake benchmark /images

RUN apk add --no-cache nano tree && \
    apk add --no-cache imagemagick6 && \
    apk add --no-cache --virtual dhash-vips-build-dependencies git build-base imagemagick6-dev jpeg-dev libpng-dev && \
    git clone -n https://github.com/dtschump/CImg.git --depth 1 --branch v.2.9.1 && \
    git -C CImg checkout HEAD CImg.h && \
    mv CImg/CImg.h usr/include/ && \
    rm -rf CImg

ARG RUBY_TAG
RUN git clone https://github.com/ruby/ruby.git --depth 1 --branch $RUBY_TAG

ARG DHASH_VIPS_TAG
ENV DHASH_VIPS_TAG $DHASH_VIPS_TAG
RUN git clone https://github.com/Nakilon/dhash-vips.git --depth 1 --branch $DHASH_VIPS_TAG && \
    cd dhash-vips && bundle install --no-cache && ruby extconf.rb && make

# RUN apk del --purge dhash-vips-build-dependencies
