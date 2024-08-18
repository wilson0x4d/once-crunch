#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
##
set -eo pipefail
apt-get -y --no-install-recommends --no-install-suggests install \
    git ssh gnupg \
    gcc-multilib g++-multilib \
    pkg-config equivs \
    sqlite3 sqlite3-tools libsqlite3-dev \
    clang llvm lld
