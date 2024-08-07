#!/bin/bash
# SPDX-FileCopyrightText: © 2023 Shaun Wilson
# SPDX-License-Identifier: MIT
#
# Copyright (C) © 2023 Shaun Wilson
#
# this script is used to install `pwsh` inside a
# container during image creation, it mainly solves
# the problem of determining platform-architecture and
# pulling the correct distribution down.
#
# example:
#
# ./install-pwsh.sh
#
##
set -eo pipefail

# Download the powershell '.tar.gz' archive
case "$(uname -m)" in
    "x86_64" | "amd64" | "x64")
        wget --quiet -O /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.4.4/powershell-7.4.4-linux-x64.tar.gz
        ;;
    "aarch64" | "arm64")
        wget --quiet -O /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.4.4/powershell-7.4.4-linux-arm64.tar.gz
        ;;
    *)
        exit 119
        ;; 
esac

# Create the target folder where powershell will be placed
mkdir -p /opt/microsoft/powershell/7

# Expand powershell to the target folder
tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7

# Set execute permissions
chmod +x /opt/microsoft/powershell/7/pwsh

# Create the symbolic link that points to pwsh
ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

# Delete Interim Files
rm -rf /tmp/powershell.tar.gz