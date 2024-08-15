#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
##
set -eo pipefail
apt-get -y install python3 python3-venv
cd /usr/local/share
python3 -m venv poetry && \
poetry/bin/pip install poetry && \
poetry/bin/poetry completions bash >> ~/.bash_completion && \
ln -s /usr/local/share/poetry/bin/poetry /usr/local/bin/poetry
