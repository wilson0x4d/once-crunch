#!/bin/pwsh
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT

$context = $pwd.Path
# pwsh on unix be like
if ([string]::IsNullOrWhiteSpace($env:HOME)) {
    $env:HOME = $env:USERPROFILE
}

# NOTE: has to be removed because it causes podman to error
Remove-item -Recurse -Force "$context/.venv" 2>&1 | Out-Null

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
#$once_crunch_remote = $(git remote get-url origin)
#$quickbms_remote = $once_crunch_remote.Replace("once-crunch", "quickbms")
Start-Process -NoNewWindow -Wait -FilePath "podman" -ArgumentList @(
    "build",
    "--arch", "amd64",
    "--os", "linux",
#    "--build-arg", "ONCE_CRUNCH_REMOTE=$once_crunch_remote",
#    "--build-arg", "QUICKBMS_REMOTE=$quickbms_remote",
    "--build-arg", "MAKE_MAX_CONCURRENCY=$([Environment]::ProcessorCount)",
    "-t", "once-crunch",
    "$context")
