# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
import argparse
import io
import json
import os
import shutil

# def format_id(target, id:str, desc:str = ""):
#     @functools.wraps(target, updated=())
#     class FormatIdClass(target):
#         __format_id__ = id
#         __format_desc__ = desc
#     return FormatIdClass

class FormatHandler:
    """the file to operate on"""
    _file:io.IOBase
    """the offset into `_file` where formatted data begins"""
    _offset:int

    def __init__(self, file:io.IOBase, offset:int):
        self._file = file
        self._offset = offset

    def check_signature(self, buf:bytes):
        raise NotImplementedError

    def decode(self, args: argparse.Namespace):
        raise NotImplementedError

    def extract_header(self):
        raise NotImplementedError

    def encode(self, input, dest:str):
        raise NotImplementedError

    def is_compatible(self):
        self._file.seek(self._offset)
        buf = self._file.read(4)
        return self.check_signature(buf)
    
    def save_json(self, data:dict, dest:str, force:bool = False):
        dest = os.path.abspath(dest)
        if os.path.isdir(dest):
            if force:
                shutil.rmtree(dest)
            else:
                raise FileExistsError(f"Cannot write to path {dest}, already exists.")
        elif os.path.isfile(dest) and not force:
            raise Exception(f'File exists {dest}.')
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        json_data = json.dumps(data, indent='\t')
        with open(dest, 'wt') as json_file:
            json_file.write(json_data)
        
    def save_binary(self, data:bytes, dest:str, force:bool = False):
        dest = os.path.abspath(dest)
        if os.path.isdir(dest):
            if force:
                shutil.rmtree(dest)
            else:
                raise FileExistsError(f"Cannot write to path {dest}, already exists.")
        elif os.path.isfile(dest) and not force:
            raise Exception(f'File exists {dest}.')
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, 'wb') as binary_file:
            binary_file.write(data)
