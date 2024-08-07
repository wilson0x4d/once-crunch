#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
##
set -eo pipefail
apt-get -y install cmake
git clone https://github.com/zrax/pycdc.git /root/code/pycdc
cd /root/code/pycdc
cmake .
make
ln -s /root/code/pycdc/pycdas /usr/local/bin/pycdas
ln -s /root/code/pycdc/pycdc /usr/local/bin/pycdc
