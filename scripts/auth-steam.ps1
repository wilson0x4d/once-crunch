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
# give steam a chance to update before proceeding to use it
steamcmd +quit 2>&1 | Out-Null 
# perform login, the auth state is cached (credentials are not stored)
steamcmd +login $AccountName +quit
