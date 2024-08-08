# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
import argparse
import importlib
from .commands import *
from .util.logging import Logger, LogLevel

_log = Logger()
_commands: dict = {}

def configure(): 
    parser = argparse.ArgumentParser(
        prog='once-crunch',
        description='A toolchain for data mining games.')
    parser.add_argument('-v', '--verbose', action='store_true')
    parser.add_argument('-f', '--force', action='store_true')
    parser.add_argument('--pvr2png', action='store_true', help='Convert PVR files to PNG files.')
    parser.add_argument('--recolor', action='store_true', help='Recolor supported images.')
    parser.add_argument('--webp', action='store_true', help='Convert supported images to webp format.')
    # `commands` sub-parsers
    subparsers = parser.add_subparsers(title='commands',dest='command',required=True)
    commands_package = importlib.import_module('once-crunch.commands')
    command_names = dir(commands_package)
    for command_name in command_names:
        if (not command_name.startswith('__')):
            command_module = importlib.import_module(f'once-crunch.commands.{command_name}')
            if (None != command_module.configure_help and None != command_module.execute):
                command_module.configure_help(subparsers)
                _commands[command_name] = command_module.execute
    return parser.parse_args()

def try_execute_command(args):
    for command in _commands:
        if args.command == command:
            fn = _commands[args.command]
            fn(args)

if ("__main__" == __name__):
    try:
        args = configure()
        if (args.verbose):
            _log.set_loglevel(LogLevel.TRACE)
            _log.debug(args)
        try_execute_command(args)
    except KeyboardInterrupt:
        _log.info("^C\x1b[0J\r\n\n\a")
        exit(0x4d)
    finally:
        _log.activity("\r\n")
