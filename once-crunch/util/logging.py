# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT

from enum import IntEnum

class LogLevel(IntEnum):
    TRACE = 0
    DEBUG = 1
    INFORMATION = 2
    WARNING = 4
    ERROR = 8

class Logger:
    _logLevel: LogLevel
    _context: str
    def __init__(self, context: str = ""):
        self._context = context
        Logger._logLevel = LogLevel.INFORMATION
    def set_loglevel(self, level: LogLevel):
        Logger._logLevel = level
    def write(self, level: LogLevel, message: str):
        if (level >= Logger._logLevel):
            if (len(self._context) > 0):
                print(f'\x1b[0m[{self._context}] {message}')
            else:
                print(message)
    def trace(self, message: str):
        self.write(LogLevel.TRACE, f'\x1b[3;2;37m{message}\x1b[23m')
    def debug(self, message: str):
        self.write(LogLevel.DEBUG, f'\x1b[2;37m{message}')
    def info(self, message: str):
        self.write(LogLevel.INFORMATION, f'\x1b[0;39m{message}')
    def warn(self, message: str):
        self.write(LogLevel.WARNING, f'\x1b[1;33m{message}')
    def error(self, message: str):
        self.write(LogLevel.ERROR, f'\x1b[1;31m{message}')
    def activity(self, message: str):
        print(f'\x1b[0m{message}\x1b[0J', end = '\r')
    def progress(self, message: str, value: float, max_value: float, force:bool = False):
        if force or (0 == value % 47):
            print(f'\x1b[0m[{value}/{max_value}] {round((value/max_value)*100.0,1)}% {message}\x1b[0J', end = '\r')
