#!/bin/pwsh
# SPDX-FileCopyrightText: 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
param(
    [parameter()]
    [switch]$NonInteractive,
    [parameter()]
    [string]$DataDir,
    [parameter()]
    [string]$LaunchTarget,
    [parameter()]
    [string]$ContainerName = "ci-once-crunch"
)
if ([String]::IsNullOrWhiteSpace($DataDir)) {
    # when not specified the datadir defaults to the
    # directory just above the git repo. this is a
    # personal convenie nce so i can access the 
    # repo from within the container (rather than)
    # the ephemeral snapshot pulled during container
    # creation.
    $context = $pwd.Path
    $DataDir = [IO.Path]::GetFullPath("$context/..")
    Write-Warning "You did not provide a -DataDir argument.`nThe data directory is defaulted to: `n$DataDir"
    Start-Sleep -Seconds 3
}
$ArgList = @(
    "run", 
    "--rm", 
    "-v", "$DataDir`:/data", 
    "-e", "DISPLAY=$(@([Net.DNS]::GetHostAddresses([Environment]::MachineName) | Where-Object { $_.AddressFamily -eq "InterNetwork" })[0].ToString()):0",
    "--name", "$ContainerName"
)

if ($NonInteractive.IsPresent) {
    $ArgList += "localhost/once-crunch:latest"
    $ArgList += "/bin/bash"
    $ArgList += "-c"
    $ArgList += "sys/activate-daemon.sh"
    Start-Process "podman" -ArgumentList $ArgList -NoNewWindow
} elseif ([string]::IsNullOrWhiteSpace($LaunchTarget)) {
    $ArgList += "-it"
    $ArgList += "localhost/once-crunch:latest"
    $ArgList += "/usr/local/bin/poetry"
    $ArgList += "shell"
    Start-Process "podman" -ArgumentList $ArgList -NoNewWindow -Wait
} else {
    $ArgList += "-it"
    $ArgList += "localhost/once-crunch:latest"
    $ArgList += $LaunchTarget
    Start-Process "podman" -ArgumentList $ArgList -NoNewWindow -Wait
}
