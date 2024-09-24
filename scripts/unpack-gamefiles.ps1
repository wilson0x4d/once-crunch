#!/bin/pwsh
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
#
# unpack-gamefiles.ps1
#
# Recursively processes all npk files in the specified directory.
#
# For the fastest export run with no options.
# 
# -For PVR files, options such as -Png, -Webp, -Jpg, -ImageRecolor will incur the use of PVRTexToolCLI which will degrade throughput.
#
# -Jpg, -Webp, and -Png are mutually exclusive options.
#
# Example, skips creation of albedo.png, normal.png, mipmap.png, and control.png files:
#
# scripts/unpack-gamefiles.ps1 -Png -ImageRecolor -Exclude "mipmap.png,normal.png,albedo.png,control.png"
#
##
param(
    [Parameter()]
    [switch]$Force,
    [Parameter()]
    [switch]$ImageRecolor,
    [Parameter()]
    [switch]$Png,
    [Parameter()]
    [switch]$Webp,
    [Parameter()]
    [switch]$Jpg,
    [Parameter()]
    [string]$Exclude
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
            if ($Jpg.IsPresent) {
                $arg_list += @("--img-format jpg")
            } elseif ($Webp.IsPresent) {
                $arg_list += @("--img-format webp")
            } elseif ($Png.IsPresent) {
                $arg_list += @("--img-format png")
            }
            if ($ImageRecolor.IsPresent) {
                $arg_list += @("--recolor")
            }
            if ($null -ne $Exclude -and ![string]::IsNullOrWhiteSpace($Exclude)) {
                $arg_list += @("--exclude", $Exclude)
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
                Recursive-Unpack $child.FullName $sub_outpath
            }
        }
    }
}

Recursive-Unpack "/data/once-human/" "/data/out"
