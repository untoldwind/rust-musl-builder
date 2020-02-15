FROM ubuntu:18.04

ARG TOOLCHAIN=stable
ARG OPENSSL_VERSION=1.0.2r

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        cmake \
        curl \
        file \
        git \
        musl-dev \
        musl-tools \
        libpq-dev \
        libsqlite-dev \
        libssl-dev \
        linux-libc-dev \
        pkgconf \
        sudo \
        xutils-dev \
        gcc-multilib-arm-linux-gnueabihf \
        && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    useradd rust --user-group --create-home --shell /bin/bash --groups sudo

RUN ln -s "/usr/bin/g++" "/usr/bin/musl-g++"

RUN echo "Building OpenSSL" && \
    ls /usr/include/linux && \
    mkdir -p /usr/local/musl/include && \
    ln -s /usr/include/linux /usr/local/musl/include/linux && \
    ln -s /usr/include/x86_64-linux-gnu/asm /usr/local/musl/include/asm && \
    ln -s /usr/include/asm-generic /usr/local/musl/include/asm-generic && \
    cd /tmp && \
    curl -LO "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" && \
    tar xvzf "openssl-$OPENSSL_VERSION.tar.gz" && cd "openssl-$OPENSSL_VERSION" && \
    env CC=musl-gcc ./Configure no-shared no-zlib -fPIC --prefix=/usr/local/musl -DOPENSSL_NO_SECURE_MEMORY linux-x86_64 && \
    env C_INCLUDE_PATH=/usr/local/musl/include/ make depend && \
    env C_INCLUDE_PATH=/usr/local/musl/include/ make && \
    make install && \
    rm /usr/local/musl/include/linux /usr/local/musl/include/asm /usr/local/musl/include/asm-generic && \
    rm -r /tmp/*

RUN echo "Building zlib" && \
    cd /tmp && \
    ZLIB_VERSION=1.2.11 && \
    curl -LO "http://zlib.net/zlib-$ZLIB_VERSION.tar.gz" && \
    tar xzf "zlib-$ZLIB_VERSION.tar.gz" && cd "zlib-$ZLIB_VERSION" && \
    CC=musl-gcc ./configure --static --prefix=/usr/local/musl && \
    make && sudo make install && \
    rm -r /tmp/*

ENV PATH=/root/.cargo/bin:/usr/local/musl/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    OPENSSL_DIR=/usr/local/musl/ \
    OPENSSL_INCLUDE_DIR=/usr/local/musl/include/ \
    DEP_OPENSSL_INCLUDE=/usr/local/musl/include/ \
    OPENSSL_LIB_DIR=/usr/local/musl/lib/ \
    OPENSSL_STATIC=1 \
    PKG_CONFIG_ALLOW_CROSS=true \
    PKG_CONFIG_ALL_STATIC=true \
    LIBZ_SYS_STATIC=1 \
    TARGET=musl \
    CARGO_HOME=/root/.cargo \
    RUSTUP_HOME=/root/.rustup

RUN mkdir -p /root/libs /root/src
WORKDIR /root/src

RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- -y --default-toolchain $TOOLCHAIN && \
    rustup target add x86_64-unknown-linux-musl && \
    rustup target add armv7-unknown-linux-musleabihf
ADD cargo-config.toml /root/.cargo/config
