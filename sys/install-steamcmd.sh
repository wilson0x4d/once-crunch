#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
##
set -eo pipefail

#
# https://askubuntu.com/questions/506909/how-can-i-accept-the-lience-agreement-for-steam-prior-to-apt-get-install/1017487#1017487
#

case "$(uname -m)" in
    "x86_64" | "amd64" | "x64")
        # to support arm64 containers, only install steamcmd when amd64
        echo steam steam/question select "I AGREE" | debconf-set-selections
        echo steam steam/license note '' | debconf-set-selections
        apt-get -y install steamcmd
        ln -s /usr/games/steamcmd /usr/local/bin/steamcmd
        steamcmd +quit
        ;;
    "aarch64" | "arm64")
        echo "STEAMCMD is not installed on arm64."
        ;;
    *)
        exit 119
        ;; 
esac
