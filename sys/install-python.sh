#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
#
# build-python.sh
#
##
set -eo pipefail

# ensure dev deps (libs, not tools)
apt-get -y install zlib1g-dev libbz2-dev libffi-dev liblzma-dev liblzo2-dev libncurses-dev libreadline-dev libsqlite3-dev libssl-dev lzma-dev tk-dev uuid-dev

# pull sources
mkdir -p /root/code
git clone https://github.com/python/cpython.git "/root/code/cpython"
cd "/root/code/cpython"

# Python 3.12
git switch 3.12
./configure
make
make install

# clean up
rm -rf /root/code/cpython
