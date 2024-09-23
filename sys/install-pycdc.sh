#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
##
set -eo pipefail
apt-get -y install cmake
# NOTE: installing own fork because of WIP edits that allow it to work
git clone -b hacks https://github.com/wilson0x4d/pycdc.git /root/code/pycdc
cd /root/code/pycdc
cmake .
make
ln -s /root/code/pycdc/pycdas /usr/local/bin/pycdas
ln -s /root/code/pycdc/pycdc /usr/local/bin/pycdc
