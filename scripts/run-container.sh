#!/bin/bash
# SPDX-FileCopyrightText: © 2024 Shaun Wilson
# SPDX-License-Identifier: MIT

NON_INTERACTIVE_MODE=0
ATTACH_MODE=0
DATA_DIR=

for arg; do
    if [[ "--non-interactive" == $arg ]]; then
        NON_INTERACTIVE_MODE=1
    fi
    if [[ "--attach" == $arg ]]; then
        ATTACH_MODE=1
    fi
    if [[ "--data-dir" == $arg ]]; then
        DATA_DIR="expect-next"
    fi
    if [[ "expect-next" == $DATA_DIR ]]; then
        DATA_DIR=$arg
    fi
done

# determine datadir
if [[ "" == "$DATA_DIR" ]]; then
    # when not specified the datadir defaults to the
    # directory just above the git repo where this
    # script "should have" been run from. this is a
    # personal convenience so i can access the 
    # repo from within the container.
    DATA_DIR=$(realpath "$PWD/..")
    echo $'You did not provide a data directory argument.\nThe data directory is defaulted to: \n$DATA_DIR'
fi

# run container
if [ 1 -eq $NON_INTERACTIVE_MODE ]; then
    podman run --rm -d -v "$DATA_DIR:/data" --name "ci-once-crunch" --platform "linux/amd64" localhost/once-crunch:latest /bin/bash -c 'while true; do sleep 30; done'
elif [ 1 -eq $ATTACH_MODE ]; then
    podman exec -it "ci-once-crunch" /bin/bash --rcfile 'sys/with-venv.sh'
else
    podman run -it --rm -v "$DATA_DIR:/data" --name "ci-once-crunch" --platform "linux/amd64" localhost/once-crunch:latest /bin/bash --rcfile 'sys/with-venv.sh'
fi
