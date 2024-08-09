#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
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
# TODO: commented out because of problem in applehv on M1 mac, will need to research problem further
#steamcmd +quit
