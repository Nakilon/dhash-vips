FROM ruby:2.7.2-slim
COPY . /pwd
RUN apt-get update && apt install --no-install-recommends -y libvips42 wget build-essential && \
    mkdir /ruby && wget -O- https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.2.tar.gz | tar xzC /ruby --strip-components=1 && \
    cd pwd && rake install && rm -rf $(pwd) && \
    rm -rf /ruby && \
    rm -rf /var/lib/apt/lists/*
