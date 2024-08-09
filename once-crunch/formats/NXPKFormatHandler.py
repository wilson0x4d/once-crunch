# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
import argparse
import io
import lz4.block
import os
import struct
import time
import zlib
import zstd
from .FormatHandler import FormatHandler
from .NXFNFormatHandler import NXFNFormatHandler
from ..util.logging import Logger
from ..util.imgtools import pvr2png, magick

_log = Logger(__name__)

_args_exclude = []
_image_file_types = [
    '.pvr',
    '.png',
    '.jpg',
    '.tga',
    '.tif',
    '.bmp',
    '.tiff',
    '.jpeg'
]

def _is_excluded(args: argparse.Namespace, target:str):
    global _args_exclude
    if (0 == len(_args_exclude) and None != args.exclude):
        _args_exclude = args.exclude.split(',')
    for exclusion in _args_exclude:
        if 0 <= target.find(exclusion):
            _log.debug(f'`{target}` is excluded by `{exclusion}`.')
            return True
    return False

def _is_imagefile(path:str):
    global _image_file_types
    noext, ext = os.path.splitext(path)
    return ext in _image_file_types

class NXPKFormatHandler(FormatHandler):
    __format_id__ = 'nxpk'
    __format_desc__ = 'NeoX Package (.npk) Data Format'
    _header:dict
    _table_entry_size:int
    _table_size:int

    def check_signature(self, buf:bytes):
        return buf.startswith(b'NXPK')
    
    def decode(self, args: argparse.Namespace):
        start_time = time.time()
        if _is_excluded(args, args.SOURCE):
            return
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
            _log.progress(progress_msg, entry_index, self._header['table_entry_count'], False)
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
            if _is_excluded(args, filepath):
                continue
            short_filename = filename.replace(f'{os.path.dirname(filename)}/', '')
            if not args.force and os.path.exists(filepath):
                # if file exists (and not args.force) skip unpacking (would-be file will still be post-processed)
                _log.progress(f'(cached) {short_filename}', i+1, self._header["table_entry_count"])
                pass
            else:
                _log.progress(f'(extract) {short_filename}', i+1, self._header["table_entry_count"], False)
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
            noext, ext = os.path.splitext(filepath)
            # image post-processing
            if _is_imagefile(filepath):
                out_ext = ext if None == args.img_format else f'.{args.img_format}'
                out_filepath = f'{noext}{out_ext}'
                if _is_excluded(args, out_filepath):
                    continue
                existing_img = None != args.img_format and os.path.isfile(out_filepath)
                # skip existing unless `--force`, this also means recoloring without changing file format requires `--force`
                if args.force or not existing_img:
                    # convert pvr to png (sometimes only as intermediary format since imagemagick can't process PVR files.)
                    pvr_file = '.pvr' == ext
                    if pvr_file and None != args.img_format:
                        _log.progress(f'(pvr2png) {short_filename}', i+1, self._header["table_entry_count"])
                        filepath = pvr2png(filepath, args.force)
                        noext, ext = os.path.splitext(filepath)
                    # optionally process image files by recoloring, converting, or some custom operation
                    if '.png' == ext or '.webp' == ext or '.jpg' == ext: # TODO: supported file extensions should be a list, not a hardcoded conditional expression
                        magick_options = {
                            'custom_args': [],
                            'img_format': args.img_format,
                            'force': True == args.force,
                            'existing_img': True == existing_img,
                            'recolor': True == args.recolor
                        }
                        _log.progress(f'(magick) {short_filename}', i+1, self._header["table_entry_count"])
                        filepath = magick(filepath, magick_options)
                        noext, ext = os.path.splitext(filepath)
                    # if extract was a PVR file, and target format is not PNG, remove intermediary PNG file to save on space
                    if pvr_file and None != args.img_format and 'png' != args.img_format:
                        # only remove if the target image format was created
                        if os.path.isfile(out_filepath) and os.path.isfile(f'{noext}.png'):
                            # removing intermediary 'png' file
                            os.remove(f'{noext}.png')
            # TODO: pyc -> py
        elapsed_time = time.time() - start_time
        _log.activity(f'Done. `{len(entry_table)}` entries took `{elapsed_time}` seconds.')

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
