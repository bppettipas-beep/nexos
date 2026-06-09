# =============================================================
#  NexOS ISO Builder — Docker Image
#  Builds nexos.iso inside a privileged Ubuntu container
#
#  Usage:
#    docker build -t nexos-builder .
#    docker run --privileged -v "$(pwd)/output:/output" nexos-builder
#
#  The ISO will appear at: output/nexos.iso (~3-4 GB)
#  Build time: 45–90 min depending on your connection
# =============================================================
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV OUT=/output

# Install host build tools
RUN apt-get update -qq && apt-get install -yq \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed \
    mtools \
    dosfstools \
    xz-utils \
    curl \
    wget \
    python3 \
    python3-pip \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install Pillow --quiet 2>/dev/null || true

# Copy project into image
COPY . /nexos

WORKDIR /nexos

# Create output directory
RUN mkdir -p /output

# ENTRYPOINT runs the build, outputs nexos.iso to /output
ENTRYPOINT ["/bin/bash", "-c", \
    "set -e && \
     cd /nexos && \
     echo 'y' | WORK=/tmp/nexos-build OUT=/output bash build/build.sh && \
     echo '' && \
     echo '=== nexos.iso ready at /output/nexos.iso ===' && \
     ls -lh /output/nexos.iso"]
