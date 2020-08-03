ARG VIPS_DOCKER_IMAGE
FROM $VIPS_DOCKER_IMAGE

# docker build - -t image2-ruby2.3.8 --build-arg VIPS_DOCKER_IMAGE=image1-ruby2.3.8 --build-arg RUBY_TAG=v2_3_8 <dev.dhash-vips.alpine.Dockerfile

RUN apk add --no-cache --virtual dhash-vips-build-dependencies git build-base

ARG RUBY_TAG
RUN git clone https://github.com/ruby/ruby.git --depth 1 --branch $RUBY_TAG

RUN git clone https://github.com/Nakilon/dhash-vips.git --depth 1 --branch alpine-compilation-issues && \
    cd dhash-vips && bundle install --no-cache && ruby extconf.rb && make
