#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT

context=`pwd`

# NOTE: has to be removed because it causes podmain to error
rm -rf "$context/.venv" 2>&1 | /dev/null

# this is a required third-party dependency. download
# it yourself and make sure the name here matches
# your downloaded filename. i only tested with "2024_R1"
#
# https://developer.imaginationtech.com/downloads/
#
mkdir -p "$context/deps" 2>&1 | /dev/null
if [ -e "$context/deps/PVRTexToolSetup" ]; then
    echo "Using cached deps/PVRTexToolSetup from previous build."
else
    if [ -e "$HOME/Downloads/PVRTexToolSetup-2024_R1.run-x64" ]; then
        cp "$HOME/Downloads/PVRTexToolSetup-2024_R1.run-x64" "$context/deps/PVRTexToolSetup"
    else
        echo "Setup file for PVRTexTool not found."
        echo "Download from: https://developer.imaginationtech.com/downloads/"
        echo "Copy into $HOME/Downloads with name: PVRTexToolSetup-2024_R1.run-x64"
        exit 1
    fi
fi

# build the container
podman build --arch "amd64" --os "linux" -t "localhost/once-crunch:latest" --squash-all "$context"
