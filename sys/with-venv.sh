#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT
##
source ~/.bashrc
export PS1='\W:\$ '

# try set window title
echo -n -e "\033]0;once-crunch\007"

source .venv/bin/activate
poetry shell
