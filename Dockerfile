FROM ubuntu:latest

ARG DEBUG=false
ARG UNAME=hostuser
ARG UID=1000
ARG GID=1000

ENV A_UID=$UID
ENV A_GID=$GID

ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y \
   adduser \
   virtme-ng \
   git \
   python3-requests \
   python3-psutil \
   python3-setuptools \
   python3-pyroute2 \
   python3-argcomplete \
   qemu-system-x86 \
   scapy \
   make \
   gcc \
   musl-dev \
   flex \
   bison \
   linux-headers-generic \
   elfutils \
   util-linux \
   coreutils \
   diffutils \
   findutils \
   file \
   bash \
   kmod \
   perl \
   libcap-dev \
   libmnl-dev \
   iproute2  \
   jq \
   libbpf-dev \
   rsync \
   libssl-dev \
   bc \
   kbd \
   pkg-config \
   iputils-ping

RUN echo $DEBUG > debug-mode

RUN addgroup --gid $A_GID $UNAME || true
RUN adduser --uid $A_UID --ingroup $UNAME --no-create-home --shell /bin/sh $UNAME || true

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
    ./configure --libdir /usr/lib/x86_64-linux-gnu && \
    make V=1

# Kernel
RUN git clone --no-single-branch --depth=1 https://github.com/linux-netdev/testing.git /nipa-data/kernel

# nipa
RUN git clone --depth=1 -b main https://github.com/p4tc-dev/new-nipa.git nipa

# Hotfix for qemu-8.2.2:
# https://github.com/arighi/virtme-ng/issues/97
RUN sed -i '/\["-serial", "none"\]/d' /usr/lib/python3/dist-packages/virtme/commands/run.py

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
