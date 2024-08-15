#!/bin/pwsh
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
#
# stitch-map.ps1
#
# Processes map tiles into singular map images.
#
# This script accepts a directory path which 
# will be scanned for map tile images.
#
# Tile images are assumed to be in the same
# format as the output image (ie. expects
# the same file extension.)
#
# Tile images are assumed to have a naming
# convention "X_Y.png".
#
# Tile image origin (0,0) is bottom-left, thus,
# this would be a 2x2 map layout:
#
# | 0x1.png | 1x1.png |
# | 0x0.png | 1x0.png |
#
# and this would be a 4x4 layout:
#
# | 0x3.png | 1x3.png | 2x3.png | 3x3.png | 
# | 0x2.png | 1x2.png | 2x2.png | 3x2.png | 
# | 0x1.png | 1x1.png | 2x1.png | 3x1.png | 
# | 0x0.png | 1x0.png | 2x0.png | 3x0.png | 
#
# If your map tiles have a different naming
# convention, or a different origin/organization,
# then this script cannot be used without
# modification.
#
# Example Usage:
#
# scripts/stich-map.ps1 -Path /data/out/ui/texpack/bigmap_res/map/8192 -Out /data/out/Nalcott.png
#
##
param(
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [Parameter(Mandatory=$true)]
    [string]$Out
)
$ErrorActionPreference = "Stop"

function Stitch-Images($source, $destination) {
    if ([System.IO.File]::Exists($destination)) {
        if (!$Force.IsPresent) {
            return
        } else {
            Remove-Item -Force $destination
        }
    }
    $ext = $destination.Replace([System.IO.Path]::GetFileNameWithoutExtension($destination), "")
    $max_x = 0
    $max_y = 0
    $image_files = @(Get-ChildItem "$source\*_*$ext")
    for ($i = 0; $i -lt $image_files.Count; $i++) {
        $noext = $image_files[$i].Name.Replace("$ext", "")
        $parts = $noext.Split("_")
        $x = [int]::Parse($parts[0])
        $y = [int]::Parse($parts[1])
        if ($x -gt $max_x) {
            $max_x = $x
        }
        if ($y -gt $max_y) {
            $max_y = $y
        }
    }
    $max_x++
    $max_y++
    $imargs = @()
    for ($y = $max_y; $y -gt 0; $y--) {
        for ($x = 0; $x -lt $max_x; $x++) {
            $imargs += "$source\$x`_$($y - 1)$ext"
        }
    }
    $imargs += "-tile"
    $imargs += "$max_x`x"
    $imargs += "-geometry"
    $imargs += "+0+0"
    $imargs += "-quality"
    $imargs += "74"
    if ($ext -eq ".png") {
        $imargs += "-define"
        $imargs += "png:compression-level=9"
    } elseif ($ext -eq ".webp") {
        $imargs += "-define"
        $imargs += "webp:lossless=true"
    }
    $imargs += "$destination"
    Start-Process "montage" -ArgumentList $imargs -Wait -NoNewWindow
}

Stitch-Images $Path $Out
