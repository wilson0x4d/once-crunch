#!/bin/pwsh
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
#
# unpack-gamefiles.ps1
#
# Recusrively processes all npk files in the specified directory.
#
# For the fastest export run with no options.
# 
# -Pvr2Png will dramatically increase export times.
#
# -ImageRecolor and -Webm options depend on -Pvr2Png
#
# -Webm will leave both a PNG and WEBM output, however, the PNG will not be recolored.
##
param(
    [Parameter()]
    [switch]$Force,
    [Parameter()]
    [switch]$Pvr2Png,
    [Parameter()]
    [switch]$ImageRecolor,
    [Parameter()]
    [switch]$Webm
)
$ErrorActionPreference = "Stop"

function Recursive-Unpack($path, $out_path) {
    $children = Get-ChildItem $path
    foreach ($child in $children) {
        if ($child.Name.EndsWith(".npk")) {
            $arg_list = @(
                "-m", "once-crunch")
            if ($Force.IsPresent) {
                $arg_list += @("--force")
            }
            if ($VerbosePreference -ne "SilentlyContinue") {
                $arg_list += @("--verbose")
            }
            if ($Pvr2Png.IsPresent) {
                $arg_list += @("--pvr2png")
            }
            if ($ImageRecolor.IsPresent) {
                $arg_list += @("--recolor")
            }
            if ($Webm.IsPresent) {
                $arg_list += @("--webm")
            }
            $arg_list += @(
                "unpack",
                "--format", "nxpk",
                $child.FullName,
                $out_path
            )
            Start-Process -Wait -NoNewWindow "python" -ArgumentList $arg_list
            if ($LASTEXITCODE -gt 0) {
                exit $LASTEXITCODE
            }
        } else {
            $attr = [IO.File]::GetAttributes($child.FullName)
            if (([System.IO.FileAttributes]::Directory -eq ($attr -bAnd [System.IO.FileAttributes]::Directory))) {
                $sub_outpath = $child.FullName.Replace($path, $out_path)
                Recursive-Unpack $child.FullName $root $sub_outpath
            }
        }
    }
}

Recursive-Unpack "/data/once-human/" "/data/out"
