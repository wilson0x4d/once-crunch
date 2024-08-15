# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT

import argparse
import importlib
import json
import os
from ..util.logging import Logger
from ..formats import *

_log = Logger(__name__)
_formatters: dict = {}

def configure_help(subparsers: argparse._SubParsersAction):
    help = 'Unpack game data.'
    parser: argparse.ArgumentParser = subparsers.add_parser(
        'unpack',
        description=f'{help}',
        help=help)
    # enumerate format handlers
    formats_package = importlib.import_module('..formats', 'once-crunch.commands')
    module_names = dir(formats_package)
    for module_name in module_names:
        if module_name.startswith('__') or module_name == 'FormatHandler':
            continue
        module = importlib.import_module(f'once-crunch.formats.{module_name}')
        member_names = dir(module)
        for member_name in member_names:
            if module_name == 'FormatHandler':
                continue
            if member_name.startswith('__') or member_name == 'FormatHandler':
                continue
            formatter_class = getattr(module, member_name)
            if not '__format_id__' in dir(formatter_class):
                continue
            if None == formatter_class.__format_id__:
                continue
            _formatters[formatter_class.__format_id__] = formatter_class
    parser.add_argument('--format', required=True, choices=_formatters, dest='fileformat')
    parser.add_argument('SOURCE', help='the input file')
    parser.add_argument('DESTINATION', help='the output directory')

def execute(args: argparse.Namespace):
    _log.info(f'..unpacking: {args.SOURCE}')
    # check SOURCE exists
    if not os.path.isfile(args.SOURCE):
        _log.error(f'File not found: {args.SOURCE}')
        return False
    # check DESTINATION exists, and is not a file, create directory if missing
    if os.path.isfile(args.DESTINATION):
        if not args.force:
            _log.error(f'Destination is not a directory, aborting.')
            return False
        else:
            os.remove(args.DESTINATION)
    os.makedirs(args.DESTINATION, exist_ok=True)
    if not args.fileformat in _formatters:
        _log.error(f'Format not supported: {args.fileformat}')
        return False
    # open input file for processing
    with open(args.SOURCE, 'rb') as source_file:
        # check formatter is compatible
        formatter_class = _formatters[args.fileformat]
        formatter = formatter_class(source_file, 0)
        if not formatter.is_compatible():
            _log.error(f'File `{args.SOURCE}` is not compatible with format `{args.fileformat}`.')
            return False
        header_data = formatter.extract_header()
        ## write header chunk to disk, skipping if already exists
        header_filename = f'__{args.fileformat}_header.json'
        header_filepath = os.path.join(args.DESTINATION, header_filename)
        if os.path.exists(header_filepath) and args.force:
            os.remove(header_filepath)
        if not os.path.exists(header_filepath):
            formatter.save_json(header_data, header_filepath, args.force)
        return formatter.decode(args)
