#!/bin/bash
# SPDX-FileCopyrightText: 2023 Shaun Wilson
# SPDX-License-Identifier: MIT
##
set -eo pipefail
#
# https://askubuntu.com/questions/506909/how-can-i-accept-the-lience-agreement-for-steam-prior-to-apt-get-install/1017487#1017487
#
echo steam steam/question select "I AGREE" | debconf-set-selections
echo steam steam/license note '' | debconf-set-selections
apt-get -y install steamcmd
ln -s /usr/games/steamcmd /usr/local/bin/steamcmd
steamcmd +quit
