# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
FROM debian:bookworm
ARG ONCE_CRUNCH_REMOTE
ARG QUICKBMS_REMOTE
ARG MAX_MAKE_JOBS=4
ARG MPDECIMAL_VERSION=2.5.1

# /root/.ssh and git-signing-keys.gpg are only necessary if you are working
# with private repo (and signing your commits) and need your keys (which i do)
RUN mkdir -p /data /root/code /root/.ssh/ /root/deps && \
    chmod 770 -R /root
ADD ssh/ /root/.ssh
ADD deps/ /root/deps
ADD sys/ /root/sys
ADD gitconfig /root/.gitconfig
RUN chmod 600 /root/.ssh/* && \
    chmod 770 /root/sys/*.sh

# some dpkg/apt voodoo
RUN cp -f /root/sys/build-dpkgequiv.sh /usr/local/bin/build-dpkgequiv && \
    cp -f /root/sys/debian.list /etc/apt/sources.list.d/ && \
    cp -f /root/sys/90norecnosug /etc/apt/apt.conf.d/ && \
    rm -f /etc/apt/sources.list.d/debian.sources && \
    dpkg --add-architecture i386 && \
    apt-get -y update && \
    apt-get -y install apt-transport-https apt-utils ca-certificates equivs && \
    apt-get -y upgrade

# gnupg (optional, for commit signing or pulling from the private repo)
ADD git-signing-keys.gpg /root/git-signing-keys.gpg
RUN apt-get -y install git ssh gnupg && if [ `stat --printf="%s" /root/git-signing-keys.gpg` -gt 10 ]; then gpg --import /root/git-signing-keys.gpg; fi

# quality of life (optional)
RUN echo "set-option -g default-shell /bin/bash" >> /root/.tmux.conf && \
    echo "alias ll='ls -alh --color=auto'" >> /root/.bashrc

# tools (required)
#
# in case we need to change a layer they are
# logically grouped and ordered by their
# likelihood of being updated. this helps
# minimize wasted time for container dev.
#
# baseline build tools
RUN apt-get -y install build-essential equivs gcc-multilib g++-multilib pkg-config
# libs/deps for builds
RUN apt-get -y install \
    libbz2-dev \
    libffi-dev \
    libgdbm-compat-dev \
    libgdbm-dev \
    liblzma-dev \
    liblzo2-dev \
    libncurses-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libssl-dev \
    lzma-dev \
    tk-dev \
    unicode \
    uuid-dev \
    zlib1g-dev

# tools (optional)
RUN apt-get -y install aptitude htop man nano tmux
# tools (required)
RUN apt-get -y install \
    buildah skopeo qemu-user-static \
    curl git imagemagick ssh tar wget \
    bzip2 zstd lzop xz-utils 7zip lzma

# libmpdec no longer available as a package
# only need this if building python from source
# RUN wget --quiet --no-check-certificate -O "/root/code/mpdecimal-${MPDECIMAL_VERSION}.tar.gz" "https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-${MPDECIMAL_VERSION}.tar.gz" && \
#     cd /root/code/ && \
#     tar xf "/root/code/mpdecimal-${MPDECIMAL_VERSION}.tar.gz"
# RUN cd "/root/code/mpdecimal-${MPDECIMAL_VERSION}" && \
#     ./configure && make && make install && \
#     cd "/root" && \
#     rm -rf "/root/code/mpdecimal-${MPDECIMAL_VERSION}" && \
#     rm "/root/code/mpdecimal-${MPDECIMAL_VERSION}.tar.gz"

# python3 (required)
RUN /root/sys/install-python.sh
# pwsh (for cross-platform scripts)
RUN /root/sys/install-pwsh.sh
# pvrtextool (for texture conversion)
RUN /root/sys/install-pvrtextool.sh

# llvm
RUN apt-get -y install clang llvm lld lldb

# Once Crunch (required, scripts/tools)
RUN git clone $ONCE_CRUNCH_REMOTE /root/code/once-crunch

# quickbms (required, for executing bms scripts)
#
# NOTE: we build from source, and, we build a privately
# maintained version. we mirror to github for public
# access and issues, but it is only a mirror. if you
# find a bug or want to contribute just ping on Discord.
#
RUN git clone $QUICKBMS_REMOTE /root/code/quickbms && \
    cd /root/code/quickbms && \
    make --jobs $MAX_MAKE_JOBS && \
    make install && \
    make clean

# steamcmd (to download game files)
RUN /root/sys/install-steamcmd.sh

# finalize
WORKDIR /root/code/once-crunch
RUN /root/sys/init-venv.sh && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /root/deps /root/sys 
