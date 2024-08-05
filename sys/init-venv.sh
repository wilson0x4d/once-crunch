#!/bin/bash
# SPDX-FileCopyrightText: 2023 Shaun Wilson
# SPDX-License-Identifier: MIT
##
set -eo pipefail
python3 -m venv --prompt "once-crunch" .venv
source .venv/bin/activate
poetry install --no-root
deactivate
