# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
import argparse
import io
import os
import struct
from .FormatHandler import FormatHandler
from ..util.logging import Logger

_log = Logger(__name__)

class NXFNFormatHandler(FormatHandler):
    __format_id__ = 'nxfn'
    __format_desc__ = 'NeoX Filenames Data Format'
    _header:dict

    def check_signature(self, buf:bytes):
        return buf.startswith(b'NXFN')

    def decode(self, args: argparse.Namespace):
        # read nxfn header
        self._header, header_size = self.extract_header()
        # if file exists skip, unless force
        header_filepath = os.path.join(args.DESTINATION, f'__nxfn_header.json')
        if os.path.exists(header_filepath) and args.force:
            os.remove(header_filepath)
        if not os.path.exists(header_filepath):
            self.save_json(
                self._header,
                header_filepath,
                args.force)
        # read nxfn data
        self._file.seek(self._offset + header_size)
        nxfn_data:bytes = self._file.read(self._header['data_size'])
        # if file exists skip, unless force
        data_filepath = os.path.join(args.DESTINATION, f'__nxfn_data.bin')
        if os.path.exists(data_filepath) and args.force:
            os.remove(data_filepath)
        if not os.path.exists(data_filepath):
            self.save_binary(
                nxfn_data,
                data_filepath,
                args.force)
        return nxfn_data.split(b'\0')
    
    def encode(self, input, dest:str):
        raise NotImplementedError

    def extract_header(self):
        header_size = 16
        self._file.seek(self._offset)
        buf = self._file.read(header_size)
        if (len(buf) < header_size):
            raise ValueError(f'Insuffucient header data, expected `{header_size}`, found `{len(buf)}`, aborting.')
        magic_number, r0, data_size, decompressed_data_size = struct.unpack('<IIII', buf)
        return {
            'magic_number': magic_number,
            'reserved0_D': r0,
            'data_size': data_size,
            'decompressed_data_size': decompressed_data_size
        }, header_size

    def is_compatible(self):
        self._file.seek(self._offset)
        buf = self._file.read(4)
        return self.check_signature(buf)
