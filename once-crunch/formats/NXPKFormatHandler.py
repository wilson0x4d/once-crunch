# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
import argparse
from dataclasses import dataclass
import io
import lz4.block
import os
import struct
import zlib
import zstd
from .FormatHandler import FormatHandler
from .NXFNFormatHandler import NXFNFormatHandler
from ..util.logging import Logger
from ..util.imgtools import pvr2png, magick

_log = Logger(__name__)

class NXPKFormatHandler(FormatHandler):
    __format_id__ = 'nxpk'
    __format_desc__ = 'NeoX Package (.npk) Data Format'
    _header:dict
    _table_entry_size:int
    _table_size:int

    def check_signature(self, buf:bytes):
        return buf.startswith(b'NXPK')
    
    def decode(self, args: argparse.Namespace):
        source_filename = args.SOURCE.replace(f'{os.path.dirname(args.SOURCE)}{os.path.sep}', '')
        dest = args.DESTINATION
        self._header = self.extract_header()
        self._table_entry_size = 28
        self._table_size = self._table_entry_size * self._header['table_entry_count']
        _log.debug({
            'header': self._header,
            'table_entry_size': self._table_entry_size,
            'table_size': self._table_size
        })
        entry_table = {}
        entry_index = 0
        progress_msg = f'(indexing) {source_filename}'
        for entry_offset in range(self._header['table_offset'], self._table_size + self._header['table_offset'], self._table_entry_size):
            table_entry = self.read_entry(entry_offset)
            entry_table[entry_index] = table_entry
            entry_index += 1
            _log.progress(progress_msg, entry_index, self._header['table_entry_count'])
        nxfn = self.decode_nxfn(self._header['table_offset'] + self._table_size, args)
        # TODO: add support for "map" files
        for i in range(len(entry_table)):
            filename = None
            if (nxfn != None):
                # use NXFN data to name files
                filename = nxfn[i].replace(b'\\', b'/').decode('utf-8')
            else:
                # TODO: implement support for "map" files
                # when a name cannot be determined, generate a subdirectory name based on the input filename
                # TODO: when generating a filename, use magic numbers to derive a file extension as well
                filename = os.path.join(
                    source_filename, 
                    f'{i}')
            filepath = os.path.join(args.DESTINATION, filename)
            short_filename = filename.replace(f'{os.path.dirname(filename)}/', '')
            if not args.force and os.path.exists(filepath):
                # if file exists (and not args.force) skip unpacking (would-be file will still be post-processed)
                _log.progress(short_filename, i+1, self._header["table_entry_count"], True)
                pass
            else:
                _log.progress(short_filename, i+1, self._header["table_entry_count"])
                entry = entry_table[i]
                self._file.seek(entry['data_offset'])
                data = self._file.read(entry['data_size'])
                match (entry['encryption_type']):
                    case 0: # none
                        pass
                    case _:
                        raise NotImplementedError(f'nxpk encryption type: {entry["encryption_type"]}')
                match (entry['compression_type']):
                    case 0: # none
                        pass
                    case 1: # zlib
                        data = zlib.decompress(data)
                    case 2: # lz4
                        data = lz4.block.decompress(data, uncompressed_size=entry['uncompressed_data_size'])
                    case 3: # zstd
                        data = zstd.decompress(data)
                    case _:
                        raise NotImplementedError(f'nxpk compression type: {entry["compression_type"]}')
                self.save_binary(data, filepath, args.force)
            # convert pvr -> png
            is_pvr = filepath.endswith('.pvr')
            if is_pvr:
                if args.pvr2png:
                    _log.progress(f'(pvr2png) {short_filename}', i+1, self._header["table_entry_count"], True)
                    filepath, existing_png = pvr2png(filepath, args.force)
                if filepath.endswith('.png'):
                    if args.recolor or args.webp:
                        _log.progress(f'(recolor) {short_filename}', i+1, self._header["table_entry_count"], True)
                        filepath = magick(filepath, {
                            'force': args.force,
                            'existing_png': existing_png,
                            'recolor': args.recolor,
                            'webp': args.webp
                        })
            # TODO pyc -> py

    def decode_nxfn(self, offset:int, args: argparse.Namespace):
        nfxn_formatter = NXFNFormatHandler(self._file, offset)
        return nfxn_formatter.decode(args)

    def extract_header(self):
        header_size = 24
        self._file.seek(self._offset)
        buf = self._file.read(header_size)
        if (len(buf) < header_size):
            raise ValueError(f'Insuffucient header data, expected `{header_size}`, found `{len(buf)}`, aborting.')
        magic_number, table_entry_count, r0, r1, r2, r3, r4, r5, table_offset = struct.unpack('<IIHHBBHII', buf)
        return {
            'magic_number': magic_number,
            'table_entry_count': table_entry_count,
            'reserved0_W': r0,
            'reserved1_W': r1,
            'reserved2_B': r2,
            'reserved3_B': r3,
            'reserved4_W': r4,
            'reserved5_D': r5,
            'table_offset': table_offset
        }

    def read_entry(self, entry_offset:int):
        self._file.seek(entry_offset, io.SEEK_SET)
        buf = self._file.read(self._table_entry_size)
        checksum, data_offset, data_size, uncompressed_data_size, data_crc, uncompressed_data_crc, compression_type, encryption_type = struct.unpack('<IIIIIIHH', buf)
        return {
             'checksum': checksum,
             'data_offset': data_offset,
             'data_size': data_size,
             'uncompressed_data_size': uncompressed_data_size,
             'data_crc': data_crc,
             'uncompressed_data_crc': uncompressed_data_crc,
             'compression_type': compression_type,
             'encryption_type': encryption_type
        }
