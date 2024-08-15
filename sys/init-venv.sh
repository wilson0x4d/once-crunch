#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
##
set -eo pipefail
python3 -m venv --prompt "once-crunch" .venv
source .venv/bin/activate
pip install poetry
if [ -e pyproject.toml ]; then
    poetry install --no-root
fi
deactivate
