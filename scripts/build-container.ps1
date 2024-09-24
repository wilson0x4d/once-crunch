#!/bin/pwsh
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
#
# scripts/build-container.ps1 [-Dev]
#
# only pass `-Dev` arg if you are doing
# private-repo development and understand the
# consequences (it bakes sensitive information
# into the container image.)
#
##
param(
    [switch]$Dev
)

$context = $pwd.Path
# pwsh on unix be like
if ([string]::IsNullOrWhiteSpace($env:HOME)) {
    $env:HOME = $env:USERPROFILE
}

# NOTE: has to be removed because it causes podman to error
Remove-item -Recurse -Force "$context/.venv" 2>&1 | Out-Null

if ($Dev.IsPresent) {
    #
    # if you don't want these copied you obviously
    # should not pass `-Dev` switch to script.
    #
    # it is for when you're doing development
    # inside the container and need access to
    # sensitive development resources.
    #
    if (![IO.Directory]::Exists("$context/ssh")) {
        if (![IO.Directory]::Exists("$env:HOME/.ssh")) {
            Write-Error "You forgot your ssh keys."
            return
        }
        Copy-Item -Recurse $env:HOME/.ssh $context/ssh
    }
    if (![IO.File]::Exists("$context/git-signing-keys.gpg")) {
        if (![IO.File]::Exists("$env:HOME/git-signing-keys.gpg")) {
            Write-Error "You forgot your signing keys."
            return
        }
        #
        # this file will ONLY exist if you've explicitly created it
        #
        Copy-Item "$env:HOME/git-signing-keys.gpg" $context/git-signing-keys.gpg
    }
    if (![IO.File]::Exists("$context/gitconfig")) {
        if (![IO.File]::Exists("$env:HOME/.gitconfig")) {
            Write-Error "You forgot your global git config."
            return
        }
        # this file for commit signing and author info,
        # since i do all my development inside the container i need this
        #
        # you can, obviously, point this at a custom config
        # or `touch gitconfig` before running this script to not copy yours in.
        #
        Copy-Item $env:HOME/.gitconfig $context/gitconfig
    }
} else {
    # if present, empty ~/.ssh will be created, which is fine
    mkdir -p "$context/ssh" 2>&1 | Out-Null
    echo "" > "$context/ssh/not-configured"
    # if empty, git will not care and will still work
    echo "" > "$context/gitconfig"
    # if empty, gnupg will not be called to import during container creation
    echo "" > "$context/git-signing-keys.gpg"
}

# this is a required third-party dependency. download
# it yourself and make sure the name here matches
# your downloaded filename. i only tested with "2024_R1"
#
# https://developer.imaginationtech.com/downloads/
#
mkdir -p "$context/deps" 2>&1 | Out-Null
if (![IO.File]::Exists("$context/deps/PVRTexToolSetup")) {
    if (![IO.File]::Exists("$env:HOME/Downloads/PVRTexToolSetup-2024_R1.run-x64")) {
        Write-Error "Setup file for PVRTexTool not found."
        Write-Error "Download from: https://developer.imaginationtech.com/downloads/"
        Write-Error "Copy into $HOME/Downloads with name: PVRTexToolSetup-2024_R1.run-x64"
        return
    }
    Copy-item "$env:HOME/Downloads/PVRTexToolSetup-2024_R1.run-x64" "$context/deps/PVRTexToolSetup"
}

# build the container
# pulling from a private repo?
$once_crunch_remote = $(git remote get-url origin)
Start-Process -NoNewWindow -Wait -FilePath "podman" -ArgumentList @(
    "build",
    "--arch", "amd64",
    "--os", "linux",
    "--build-arg", "ONCE_CRUNCH_REMOTE=$once_crunch_remote",
    "--build-arg", "MAKE_MAX_CONCURRENCY=$([Environment]::ProcessorCount)",
    "-t", "once-crunch",
    "$context")
