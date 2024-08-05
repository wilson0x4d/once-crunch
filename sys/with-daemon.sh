#!/bin/bash
# SPDX-FileCopyrightText: 2023 Shaun Wilson
# SPDX-License-Identifier: MIT
##
set -eo pipefail
[[ -d .venv ]] || python3 -m venv --prompt "once-crunch" .venv
source .venv/bin/activate
pip install -r 