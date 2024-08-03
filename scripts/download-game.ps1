#!/bin/pwsh
# SPDX-FileCopyrightText: 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
param(
    [Parameter(Mandatory = $true)]
    [string]$AccountName
)
if ([string]::IsNullOrWhiteSpace($AccountName)) {
    Write-Error "Required 'Account Name' was not provided. Aborting."
    return
}
steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir /data/game +login $AccountName +app_update 2139460 +quit
