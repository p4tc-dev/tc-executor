FROM alpine:edge

ARG DEBUG=false
ARG UNAME=hostuser
ARG UID=1000
ARG GID=1000

RUN echo $DEBUG > debug-mode
RUN addgroup -g $GID $UNAME
RUN adduser -u $UID -G $UNAME -H -D -s /bin/ash $UNAME

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
   musl-dev \
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
   perl \
   iptables-dev \
   libcap-dev \
   libmnl-dev \
   iproute2 \
   jq \
   libbpf-dev \
   rsync \
   openssl-dev

RUN mkdir -p /tmp/kernel-patches && \
    mkdir -p /tmp/iproute2-patches

COPY tdc.config /tmp
COPY tdc-debug.config /tmp
COPY kernel-patches /tmp/kernel-patches/
COPY iproute2-patches /tmp/iproute2-patches/
COPY configs /tmp/configs/

RUN git config --global user.email foo@bar.com
RUN git config --global user.name foo@bar.com

# iproute2
RUN git clone https://git.kernel.org/pub/scm/network/iproute2/iproute2-next.git /nipa-data/iproute2
RUN cd /nipa-data/iproute2 && \
	git remote add stable https://git.kernel.org/pub/scm/network/iproute2/iproute2.git && \
	git fetch --all && \
	git merge stable/main

RUN if [ "$(find /tmp/iproute2-patches/ -name *.patch)" ]; then  \
	cd /nipa-data/iproute2; \
	git apply /tmp/iproute2-patches/*.patch; \
    fi

RUN cd /nipa-data/iproute2/ && \
    ./configure && \
    make

# Kernel
RUN git clone --no-single-branch --depth=1 https://github.com/linux-netdev/testing.git /nipa-data/kernel

# nipa
RUN git clone --depth=1 -b main https://github.com/p4tc-dev/new-nipa.git nipa

COPY entrypoint.sh /entrypoint.sh

# Hotfix for qemu-8.2.2:
# https://github.com/arighi/virtme-ng/issues/97
RUN sed -i '/\["-serial", "none"\]/d' /usr/lib/python3.11/site-packages/virtme/commands/run.py

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
