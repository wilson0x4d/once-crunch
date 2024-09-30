# Once Crunch

A containerized toolchain for data mining the game "Once Human."

## Legal

**DISCLAIMER**: Herein the term THE GAME shall refer to the Windows PC video game title "Once Human" and all assets it is composed of, which are the property of NetEase, Inc. The term THE TOOL collectively refers to the assets and methods which "Once Crunch" is composed of, which are not the property of NetEase, Inc. THE TOOL facilitates FAIR USE as defined under United States Copyright Law. THE TOOL does not circumvent copy protection that effectively controls access to THE GAME. THE TOOL does not modify the THE GAME. THE TOOL does not seek to reproduce, redistribute, monetize, nor damage THE GAME. THE TOOL is not itself composed of any assets of THE GAME which would be protected under United States Copyright Law.

**TERMS OF USE**: By retaining a copy of the THE TOOL you agree to release its creators and contributors of all liability, and you also agree to assume sole responsibility for any damages caused by your use, misuse, or inability to use THE TOOL. If you are unwilling or lawfully unable to agree with these terms you must immediately cease use of the THE TOOL and destroy all copies in your possession.

**LICENSE**: THE TOOL is released under the MIT LICENSE, and Copyright of any novel component or derivative work is held by its respective creator(s) and/or contributor(s). A copy of this license and the full terms of the license should have been received in a file named "LICENSE" when you received THE TOOL. Any reproduction or derivative of THE TOOL should include a copy of the MIT LICENSE, and relevant Copyright notices must be retained.

## Quick Start

### Prerequisites

You should be able to use Windows, Linux, or macOS as a "Host environment", with the exception that "Apple Silicon" has a broken "applehv" implementation and certain tools will not work correctly (container image will fail, and importing an image from another host will not allow the affected tools to work.)

The scripts provided expect the environment has the following:

- [Podman](https://podman.io/); a cross-platform tool that manages containers, pods, and images.
- [Git](https://git-scm.com/); a free and open source distributed version control system.
- [PowerShell](https://github.com/PowerShell/PowerShell) or `bash`, the PowerShell scripts will run on Windows, Linux, and macOS. For bootstrapping/installation steps both `pwsh` and `bash` scripts are provided. Internal to the container most scripts have been updated to use Python.

You could forego these pre-reqs, you will however need to perform dependent tasks manually through alternative means.

### Storage

At the time of this writing, the game requires approximately 50GiB of storage. Once Crunch will consume an additional 100-200GiB of storage depending on how you use it. When running the container you should pass a "data directory" parameter (`-DataDir`) specifying a directory on a storage volume which has sufficient space.

### Containers

The creators of Once Crunch use `podman`, but you could adapt to using `docker`, `kubernetes`, `krunkit`, or any other OCI solution you prefer which is capable of running a container image **_interactively_**.

We do not publish a container image, you create an image yourself. You should not trust any published image identifying as Once Crunch. Full Stop.

### Installation

At this point you should have installed and configured prerequisites, confirming they work correctly, and you should have verified there is sufficient storage available to download a copy of the game. We will assume you have not cloned the repo yet:

```sh
#
# create a working directory where you can
# create a complete mess
#
mkdir my-mess
cd my-mess
#
# clone the repo for initial boostrapping
#
git clone https://github.com/wilson0x4d/once-crunch.git
#
# build the container
#
cd once-crunch
scripts/build-container.ps1
#
# .. wait ...
#
podman image ls
#
# you should see `localhost/once-crunch`
#
```

## Usage

Once Crunch is designed to be expanded over time. In its current state it is capable of:

- Processing game files and extracting all assets.
- Constructing a hierarchical copy of assets.
- Converting all textures into PNG, WEBP, or JPG.
- Post-processing converted textures.

Making use of Once Crunch is a matter of running one or more scripts and inspecting the results.

At its core Once Crunch is a series of python modules wrapped by shell scripts, and it can be easily modified to operate on data from any game.

To get started you will run the container, which should drop you into a `venv` shell:

```bash
# run the container image..
#
scripts/run-container.ps1
#
# a warning about not specifying a `-DataDir`
# is expected. You are encouraged to create a
# a dedicated data directory but it is not
# required as long as you have sufficient
# storage available where you've cloned the
# repo. By default the container will use the
# PARENT DIRECTORY of the repo (not the repo
# directory) for storing files.
#
# if successful you should see a container shell.
#
# Once Crunch is ready for use.
#
```

### Game Files

Once Crunch does not contain a copy of any game files. You will need to acquire game files through regular means. The container includes an installation of `steamcmd` which you could use, or, you could manually download and copy the game files to the data directory.

#### Manual Installation/Copying

If you manually install/copy the game files you should know that Once Crunch expects the root of the game to be the directory `/data/once-human` inside of the container, and, the `-DataDir` parameter you pass to `run-container.ps1` gets mapped to `/data/` (too obvious?) If you followed the instructions above the "once-human" directory should exist side-by-side with the "once-crunch" directory created by `git clone`.

#### Using `steamcmd`

To install using `steamcmd` there are two scripts you can use from inside the container, or you can leverage steamcmd manually. The first script will auth you to Steam servers. The second will allow you to download the game from Steam servers after you have auth'd. 

Unfortunately, downloading the game via `steamcmd` requires a login, but, the game is free and you can create an account just for downloading if you prefer (a best practice, actually.)

```sh
#
# steam auth.
#
# from inside the container:
#
cd /root/code/once-crunch 
scripts/auth-steam.ps1 youraccount@email.com
```

You will be prompted by `steamcmd` for your password, and if you have an authenticator (and you should) `steamcmd` will also prompt for an authenticator code.

After successful login you will not need to enter credentials again unless you restart the container (auth is not persistent.)

```sh
#
# steam download.
#
# from inside the container:
#
cd /root/code/once-crunch
scripts/download-game.ps1 youraccount@email.com
#
# ... "a few minutes later" ...
#
ll /data/once-human
#
# you should see the game files
#
```

At this point you now have Once Crunch installed and the game files available.

### Unpack Game Files

```bash
#
# from inside the container
#
scripts/unpack-gamefiles --png --image-recolor --exclude "mipmap.png,normal.png,albedo.png,control.png"
```

### Deobfuscate, Disassemble, and Decompile PYC Files

```bash
#
# from inside the container
#
scripts/process-pycfiles --force --rules pycdo/once-human.pycrules --target /data/out
#
# when complete you will have some "*.pycbak" files which
# are copies of the origina "*.pyc" files. You will also
# have some "*.pyasm" and "*.py" files.
#
# Worth pointing out that the decompiler used is `pycdc` which
# has a lot of problems on any pyc newer than Python 3.10, thus
# this toolchain is using a MODIFIED version of pycdc to get the
# results it does. While the pyasm files should be 100% accurate
# and complete, the resulting py files are mostly invalid (will
# not recompile) -- still, the results are enough as a learning
# aid.
#
```

## Why?

For fun. Once Human is an engaging gaming experience and this work benefits the gaming community, both game players and the game devs, by enhancing that experience through value-added resources that otherwise would not be possible (or, would exist with a much degraded level of quality which would reflect poorly on the game.)

## Conclusion

Keep in mind that with power comes responsibility. 

Just because you can legally ACCESS data does not mean you can legally USE data.

**Do not publish any data without first consulting a lawyer on FAIR USE, COPYRIGHT LAW, DMCA, and any local or international laws you may be subject to.**

Enjoy!
