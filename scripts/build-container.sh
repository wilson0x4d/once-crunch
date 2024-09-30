#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
#
# scripts/build-container.ps1 [--dev]
#
# only pass `--dev` arg if you are doing
# private-repo development and understand the
# consequences (it bakes sensitive information
# into the container image.)
#
##

context=`pwd`

# NOTE: has to be removed because it causes podmain to error
rm -rf "$context/.venv" 2>&1 | /dev/null


DEV_MODE=0
for arg; do
    if [[ "--dev" == $arg ]]; then
        DEV_MODE=1
    fi
done

# if [ 1 -eq $DEV_MODE ]; then
#     cp -rf $HOME/.ssh $context/ssh
#     cp -f $HOME/git-signing-keys.gpg $context/git-signing-keys.gpg
#     cp -f $HOME/.gitconfig $context/gitconfig    
# else
#     mkdir -p "$context/ssh" 2>&1 | Out-Null
#     echo "" > "$context/ssh/not-configured"
#     echo "" > "$context/gitconfig"
#     echo "" > "$context/git-signing-keys.gpg"
# fi

# this is a required third-party dependency. download
# it yourself (the linux binary) and make sure the name here matches
# your downloaded filename. i only tested with "2024_R1"
#
# https://developer.imaginationtech.com/downloads/
#
mkdir -p "$context/deps" 2>&1 | /dev/null
if [ -e "$context/deps/PVRTexToolSetup" ]; then
    echo "Using cached deps/PVRTexToolSetup from previous build."
else
    if [ -e "$HOME/Downloads/PVRTexToolSetup.run-x64" ]; then
        cp "$HOME/Downloads/PVRTexToolSetup.run-x64" "$context/deps/PVRTexToolSetup"
    else
        echo "Setup file for PVRTexTool not found."
        echo "Download from: https://developer.imaginationtech.com/downloads/"
        echo "Copy into $HOME/Downloads with name: PVRTexToolSetup.run-x64"
    fi
fi

case "$(uname -m)" in
    "x86_64" | "amd64" | "x64")
        arch="amd64"
        ;;
    "aarch64" | "arm64")
        arch="arm64"
        ;;
    *)
        exit 119
        ;; 
esac

# build the container
podman build --arch "$arch" --os "linux" -t "localhost/once-crunch:latest" --squash-all "$context"
