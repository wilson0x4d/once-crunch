#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
##
set -eo pipefail

case "$(uname -m)" in
    "x86_64" | "amd64" | "x64")
        # to support arm64 containers, only install pvrtextool when amd64
        chmod 700 /root/deps/PVRTexToolSetup && \
            cd /root/deps/ && \
            ./PVRTexToolSetup --unattendedmodeui minimal --installer-language en --mode unattended && \
            ln -s /opt/Imagination\ Technologies/PowerVR_Graphics/PowerVR_Tools/PVRTexTool/CLI/Linux_x86_64/PVRTexToolCLI /usr/bin/PVRTexToolCLI
        ;;
    "aarch64" | "arm64")
        echo "PVRTexTool is not installed on arm64."
        ;;
    *)
        exit 119
        ;; 
esac
