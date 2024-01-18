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
   bash \
   kmod \
   iproute2 \
   perl

RUN mkdir -p /nipa-data/json && \
    mkdir -p /nipa-data/outputs && \
    mkdir -p /tmp/kernel-patches

COPY tdc.config /tmp
COPY kernel-patches /tmp/kernel-patches/

RUN mkdir -p /nipa-data/json && \
    mkdir -p /nipa-data/outputs

RUN git clone --depth=1 https://github.com/linux-netdev/testing.git /nipa-data/kernel && \
    cd /nipa-data/kernel && \
    git remote set-branches origin '*' && \
    git fetch -v --depth=1 && \
    git apply /tmp/kernel-patches/*

# Clone nipa
RUN git clone --depth=1 -b dev https://github.com/tammela/nipa.git

# Make nipa run in one shot mode
ENV NIPA_FETCHER_COUNT=3

ENTRYPOINT ["/usr/bin/python3", "/nipa/contest/remote/vmksft.py", "/tmp/tdc.config"]
