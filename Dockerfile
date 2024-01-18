FROM alpine:edge

RUN echo '@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories
RUN echo '@community http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories

RUN apk update && apk add --no-cache \
   virtme-ng@testing \
   git \
   py3-requests \
   py3-psutil \
   py3-setuptools \
   py3-pyroute2 \
   py3-argcomplete \
   qemu-system-x86_64@community \
   scapy@community \
   make \
   gcc \
   libc-dev \
   flex \
   bison \
   linux-headers \
   elfutils-dev \
   util-linux \
   coreutils \
   diffutils \
   findutils \
   file \
   perl

COPY tdc.config /tmp

RUN mkdir -p /nipa-data/json && \
    mkdir -p /nipa-data/outputs

RUN git clone --depth=1 https://github.com/linux-netdev/testing.git /nipa-data/kernel && \
    cd /nipa-data/kernel && \
    git remote set-branches origin '*' && \
    git fetch -v --depth=1 && \
    make defconfig

# Clone nipa
RUN git clone --depth=1 -b dev https://github.com/tammela/nipa.git
