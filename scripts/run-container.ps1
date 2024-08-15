#!/bin/pwsh
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
param(
    [parameter()]
    [switch]$NonInteractive,
    [parameter()]
    [switch]$Attach,
    [parameter()]
    [string]$DataDir,
    [parameter()]
    [string]$ContainerName = "ci-once-crunch"
)
if ([String]::IsNullOrWhiteSpace($DataDir)) {
    # when not specified the datadir defaults to the
    # directory just above the git repo. this is a
    # personal convenience so i can access the 
    # repo from within the container (rather than)
    # the ephemeral snapshot pulled during container
    # creation.
    $context = $pwd.Path
    $DataDir = [IO.Path]::GetFullPath("$context/..")
    Write-Warning "You did not provide a -DataDir argument.`nThe data directory is defaulted to: `n`n`t$DataDir`n"
    Start-Sleep -Seconds 3
}

# powershell try set window caption
$Host.UI.RawUI.WindowTitle = "once-crunch"

if ($NonInteractive.IsPresent) {
    # start the container in 'background mode'
    $ArgList = @(
        "run", 
        "--rm",
        "-d",
        "-v", "$DataDir`:/data", 
        "-e", "DISPLAY=$(@([Net.DNS]::GetHostAddresses([Environment]::MachineName) | Where-Object { $_.AddressFamily -eq "InterNetwork" })[0].ToString()):0",
        "--platform", "linux/amd64",
        "--name", "$ContainerName",
        "localhost/once-crunch:latest",
        "/bin/bash", "-c", "while true; do sleep 30; done"
    )
    Start-Process "podman" -ArgumentList $ArgList -NoNewWindow
} elseif ($Attach.IsPresent) {
    # attach to a 'background mode' container
    $ArgList = @(
        "exec", 
        "-it",
        "$ContainerName",
        "/bin/bash", "--rcfile", "sys/with-venv.sh"
    )
    Start-Process "podman" -ArgumentList $ArgList -NoNewWindow -Wait
} else {
    # run the container interactively
    $ArgList = @(
        "run",
        "-it",
        "--rm", 
        "-v", "$DataDir`:/data", 
        "-e", "DISPLAY=$(@([Net.DNS]::GetHostAddresses([Environment]::MachineName) | Where-Object { $_.AddressFamily -eq "InterNetwork" })[0].ToString()):0",
        "--platform", "linux/amd64",
        "--name", "$ContainerName",
        "localhost/once-crunch:latest"
    )
    Start-Process "podman" -ArgumentList $ArgList -NoNewWindow -Wait
}
