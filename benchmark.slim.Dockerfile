FROM ruby:slim
RUN apt-get update && apt-get install -y --no-install-recommends wget && \
    wget -O /usr/local/include/CImg.h https://raw.githubusercontent.com/GreycLab/CImg/3d1fc212ffe933cb2bc841e504920e5a67e676b8/CImg.h && \
    ( \
      apt-get install -y --no-install-recommends git build-essential libmagickcore-dev libvips libjpeg-dev ; \
      apt-get install -y --no-install-recommends git build-essential libmagickcore-dev libvips libjpeg-dev --fix-missing \
    )
