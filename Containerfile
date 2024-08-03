# SPDX-FileCopyrightText: 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
#
# i've been using debian for probably 20 years and
# this is just a personal preference. using bookworm
# (deb-12) for stable ports, broad support, and
# third-party compatibility
#
FROM debian:bookworm
ARG ONCE_CRUNCH_REMOTE
ARG QUICKBMS_REMOTE

# /root/.ssh and git-signing-keys.gpg are only necessary if you are working
# with private repo (and signing your commits) and need your keys (which i do)
RUN mkdir -p /data /root/code /root/.ssh/ /root/deps && \
    chmod 770 -R /root
ADD ssh/ /root/.ssh
ADD deps/ /root/deps
ADD gitconfig /root/.gitconfig
RUN chmod 600 /root/.ssh/*

# yes, the double "update" is required
RUN echo "deb http://ftp.us.debian.org/debian bookworm main non-free" > /etc/apt/sources.list.d/non-free.list && \
    dpkg --add-architecture i386 && \
    apt-get -y update && \
    apt-get -y install software-properties-common apt-transport-https && \
    apt-get -y upgrade

# gnupg (optional, for commit signing or pulling from the private repo)
ADD git-signing-keys.gpg /root/git-signing-keys.gpg
RUN apt-get -y install git ssh gnupg && if [ `stat --printf="%s" /root/git-signing-keys.gpg` -gt 10 ]; then gpg --import /root/git-signing-keys.gpg; fi

# quality of life tools (optional)
RUN apt-get -y install aptitude wget nano tmux htop man && \
echo "set-option -g default-shell /bin/bash" >> /root/.tmux.conf && \
echo "alias ll='ls -alh --color=auto'" >> /root/.bashrc

# pvrtextool (for texture conversion)
#
# if you're not going to perform PVR conversion this is
# not necessary, but many mobile games use PVR and this
# is the most reliabile tool at this point.
#
RUN chmod 700 /root/deps/PVRTexToolSetup && \
    cd /root/deps/ && \
    ./PVRTexToolSetup --unattendedmodeui minimal --installer-language en --mode unattended && \
    ln -s /opt/Imagination\ Technologies/PowerVR_Graphics/PowerVR_Tools/PVRTexTool/CLI/Linux_x86_64/PVRTexToolCLI /usr/bin/PVRTexToolCLI

# steamcmd (to download game files)
#
# https://askubuntu.com/questions/506909/how-can-i-accept-the-lience-agreement-for-steam-prior-to-apt-get-install/1017487#1017487
#
RUN echo steam steam/question select "I AGREE" | debconf-set-selections && \
    echo steam steam/license note '' | debconf-set-selections && \
    apt-get -y install steamcmd && \
    ln -s /usr/games/steamcmd /usr/local/bin/steamcmd && \
    steamcmd +quit

# tools (required)
#
# in case i need to change a layer, they are logically grouped:
#
# - containers
# - git
# - GCC and LLVM toolchains
# - python3
# - imagemagick
# - compression
#
RUN apt-get -y install buildah skopeo qemu-user-static
RUN apt-get -y install imagemagick
RUN apt-get -y install git ssh
RUN apt-get -y install bzip2 zstd lzop xz-utils 7zip
RUN apt-get -y install build-essential gcc-multilib g++-multilib zlib1g-dev liblzo2-dev libssl-dev unicode
RUN apt-get -y install clang llvm lld lldb
RUN apt-get -y install python3 python3-venv python3-virtualenv python3-poetry

# Once Crunch (required, scripts/tools)
RUN git clone $ONCE_CRUNCH_REMOTE /root/code/once-crunch && \
    chmod 777 /root/code/once-crunch/scripts/install-pwsh.sh && \
    /root/code/once-crunch/scripts/install-pwsh.sh

# quickbms (required, for executing bms scripts)
#
# NOTE: we build from source, and, we build a privately
# maintained version. we mirror to github for public
# access and issues, but it is only a mirror. if you
# find a bug or want to contribute just ping on Discord.
#
RUN git clone $QUICKBMS_REMOTE /root/code/quickbms && \
    cd /root/code/quickbms && \
    make --jobs && \
    make install && \
    make clean

# TODO: default exec for non-interactive mode
