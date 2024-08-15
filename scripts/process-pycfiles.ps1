#!/bin/pwsh
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
#
# deobfuscate-pycfiles.ps1
#
##
param(
    [Parameter(Mandatory=$true)]
    [string]$Rules,
    [Parameter()]
    [switch]$Force,
    [Parameter()]
    [switch]$ForceDas,
    [Parameter()]
    [switch]$ForceDc
)
$ErrorActionPreference = "Stop"

$Rules = [IO.Path]::GetFullPath($Rules)

if (![IO.File]::Exists($Rules)) {
    Write-Error "Rules file is missing or inaccessible: $Rules"
    exit(1)
}

function Process-Directory($path) {
    Write-Host -NoNewLine "Processing pycfiles in: $path$([char]0x1b)[0J`r"
    $children = Get-ChildItem $path
    foreach ($child in $children) {
        if ($child.Name.EndsWith(".pyc") -and !$child.Name.EndsWith(".do.pyc")) {
            Write-Host ">> $($child.FullName)"
            $input_filename = $child.FullName
            $pycdo_filename = $input_filename.Replace(".pyc", ".do.pyc")
            if ($Force.IsPresent -or ![IO.File]::Exists($pycdo_filename)) {
                Start-Process -Wait -NoNewWindow "pycdo" -ArgumentList @(
                    $input_filename,
                    $pycdo_filename,
                    "--rules", $Rules,
                    "--force", "--silent"
                )
            }
            if ([IO.File]::Exists($pycdo_filename)) {
                $pycdas_filename = $input_filename.Replace(".pyc", ".do.pyasm")
                if ($ForceDas.IsPresent -or $Force.IsPresent -or ![IO.File]::Exists($pycdas_filename)) {
                    pycdas $pycdo_filename 2>&1 > "$pycdas_filename"
                }
                $pycdc_filename = $input_filename.Replace(".pyc", ".do.py")
                if ($ForceDc.IsPresent -or $Force.IsPresent -or ![IO.File]::Exists($pycdc_filename)) {
                    pycdc $pycdo_filename 2>&1 > "$pycdc_filename"
                }
            }
        } elseif (-1 -eq $child.FullName.IndexOf(".")) {
            $attr = [IO.File]::GetAttributes($child.FullName)
            if (([System.IO.FileAttributes]::Directory -eq ($attr -bAnd [System.IO.FileAttributes]::Directory))) {
                Process-Directory $child.FullName
            }
        }
    }
}

Process-Directory "/data/out"