# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
FROM debian:bookworm
ARG ONCE_CRUNCH_REMOTE=https://github.com/wilson0x4d/once-crunch.git
ARG PYCDO_REMOTE=https://github.com/wilson0x4d/pycdo.git

RUN mkdir -p /data /root/code
ADD deps /root/deps
ADD sys /root/sys
RUN chmod 770 /root/sys/*.sh

# required apt updates
RUN cp -f /root/sys/build-dpkgequiv.sh /usr/local/bin/build-dpkgequiv && \
    cp -f /root/sys/debian.list /etc/apt/sources.list.d/ && \
    cp -f /root/sys/90norecnosug /etc/apt/apt.conf.d/ && \
    rm -f /etc/apt/sources.list.d/debian.sources
RUN dpkg --add-architecture i386 && \
    apt-get -y update
# prevent unintended installation of 'system' python3
RUN apt-mark hold python3 && \
    apt-mark hold python3.11 && \
    apt-get -y install apt-transport-https apt-utils ca-certificates equivs && \
    apt-get -y upgrade

# quality of life (optional)
RUN apt-get -y --no-install-recommends --no-install-suggests install aptitude htop man nano tmux && \
    echo "set-option -g default-shell /bin/bash" >> /root/.tmux.conf && \
    echo "alias ll='ls -alh --color=auto'" >> /root/.bashrc

# baseline build env
RUN /root/sys/install-buildtools.sh

# tools (required)
RUN apt-get -y install \
    qemu-user-static curl \
    imagemagick tar wget \
    bzip2 zstd lzop xz-utils lzma

# python3 (required)
RUN /root/sys/install-python.sh
# pwsh (for cross-platform scripts)
RUN /root/sys/install-pwsh.sh
# pvrtextool (for texture conversion)
RUN /root/sys/install-pvrtextool.sh
# pycdc (for pyc decompilation)
RUN /root/sys/install-pycdc.sh

# Once Crunch (required, scripts/tools)
RUN git clone $ONCE_CRUNCH_REMOTE /root/code/once-crunch

# pycdo (to deobfuscate pycfiles)
RUN git clone $PYCDO_REMOTE /root/code/pycdo && \
    ln -s "/root/code/pycdo/src/pycdo" "/usr/bin/pycdo"

# steamcmd (to download game files)
RUN /root/sys/install-steamcmd.sh

# finalize
WORKDIR /root/code/once-crunch
RUN /root/sys/init-venv.sh && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /root/deps /root/sys 
