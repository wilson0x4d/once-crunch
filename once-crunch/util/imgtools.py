# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
#
# imgtools.py
#
# image processing tools
##

from genericpath import isfile
import os
import shutil
import subprocess
from ..util.logging import Logger

__path_PVRTexToolCLI = shutil.which('PVRTexToolCLI')
__path_magick = shutil.which('convert')

_log = Logger(__name__)

def pvr2png(filepath:str, force:bool):
    tool_path = __path_PVRTexToolCLI
    if None == tool_path or 0 >= len(tool_path):
        return filepath
    png_filepath = filepath.replace('.pvr', '.png')
    if os.path.isfile(png_filepath):
        if force:
            os.remove(png_filepath)
        else:
            return png_filepath, True
    proc = subprocess.Popen(
        [
            tool_path,
            '-i', filepath,
            '-noout',
            '-d', png_filepath
        ],
        stderr=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL)
    proc.wait()
    if os.path.isfile(png_filepath):
        return png_filepath, False
    return filepath, False

def magick(filepath:str, options:dict):
    tool_path = __path_magick
    if None == tool_path or 0 >= len(tool_path):
        _log.debug(f'magick[1]: {filepath}, {options}')
        return filepath
    if options['existing_png'] and not options['webp'] and not options['force']:
        _log.debug(f'magick[2]: {filepath}, {options}')
        return filepath
    out_filepath, ext = os.path.splitext(filepath)
    if options['webp']:
        # write new "webp" file
        out_filepath = f'{out_filepath}.webp'
    else:
        # overwrite input file
        out_filepath = filepath
    if filepath != out_filepath and os.path.isfile(out_filepath):
        if options['force']:
            os.remove(out_filepath)
        else:
            _log.debug(f'magick[4]: {filepath}, {options}')
            return out_filepath
    magick_args = [
        tool_path,
        filepath,
        '-strip'
    ]
    if options['webp']:
        magick_args += [
            '-colorspace', 'sRGB',
            '-level', '45%,95%',
            '-colorspace', 'RGB'
            '-define', 'webp:lossless=true'
        ]
    elif options['recolor']: # assumes png
        magick_args += [
            '-colorspace', 'sRGB',
            '-modulate', '105,150',
            '-level', '30%,95%',
            '-colorspace', 'RGB',
            '-define', 'png:lossless=true'
        ]
    else: # no action
        _log.debug(f'magick[5]: {filepath}, {options}')
        return out_filepath
    magick_args += [
        '-quality', '100',
        out_filepath
    ]
    proc = subprocess.Popen(magick_args)
    proc.wait()
    _log.debug(f'magick[6]: {filepath}, {options}')
    return out_filepath
