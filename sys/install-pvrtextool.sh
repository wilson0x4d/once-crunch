#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
##
set -eo pipefail
chmod 700 /root/deps/PVRTexToolSetup && \
    cd /root/deps/ && \
    ./PVRTexToolSetup --unattendedmodeui minimal --installer-language en --mode unattended && \
    ln -s /opt/Imagination\ Technologies/PowerVR_Graphics/PowerVR_Tools/PVRTexTool/CLI/Linux_x86_64/PVRTexToolCLI /usr/bin/PVRTexToolCLI
