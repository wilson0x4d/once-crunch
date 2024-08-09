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

_path_PVRTexToolCLI = shutil.which('PVRTexToolCLI')
_path_magick = shutil.which('convert')

_log = Logger(__name__)

def pvr2png(filepath:str, force:bool):
    global _path_PVRTexToolCLI
    tool_path = _path_PVRTexToolCLI
    if None == tool_path or 0 >= len(tool_path):
        return filepath
    png_filepath = filepath.replace('.pvr', '.png')
    if os.path.isfile(png_filepath):
        if force:
            os.remove(png_filepath)
        else:
            return png_filepath
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
    if not os.path.isfile(png_filepath):
        _log.warn(f'pvr2png() did not produce any output for: {filepath}')
        return filepath
    return png_filepath

def magick(filepath:str, options:dict):
    global _path_magick
    tool_path = _path_magick
    if None == tool_path or 0 >= len(tool_path):
        _log.debug(f'magick[1]: {filepath}, {options}')
        return filepath
    if options['existing_img'] and not options['force']:
        _log.debug(f'magick[2]: {filepath}, {options}')
        return filepath
    noext, ext = os.path.splitext(filepath)
    if options['img_format']:
        ext = f'.{options["img_format"]}'
    out_filepath = f'{noext}.{ext}'
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
    if len(options['custom_args']) > 0:
        magick_args += options['custom_args']
    if ext == '.webp':
        if options['recolor']:
            magick_args += [
                '-colorspace', 'sRGB',
                '-level', '45%,95%',
                '-colorspace', 'RGB'
            ]
        magick_args += [
            '-define', 'webp:lossless=true'
        ]
    elif ext == '.png':
        if options['recolor']:
            magick_args += [
                '-colorspace', 'sRGB',
                '-modulate', '105,150',
                '-level', '30%,95%',
                '-colorspace', 'RGB',
            ]
        magick_args += [
            '-define', 'png:lossless=true'
        ]
    # removed, we still perform `-strip` in this case
    # elif filepath == out_filepath and (0 == len(options['custom_args']) or not options['recolor']):
    #     # no `--recolor`, no `custom_args`, and file extensions are identical, nothing to do
    #     _log.debug(f'magick[5]: {filepath}, {options}')
    #     return out_filepath
    magick_args += [
        '-quality', '100',
        out_filepath
    ]
    proc = subprocess.Popen(magick_args)
    proc.wait()
    if not os.path.isfile(out_filepath):
        _log.warn(f'magick() did not produce an output file for: {filepath}')
        return filepath
    _log.debug(f'magick[6]: {filepath}, {options}')
    return out_filepath
