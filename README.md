# Once Crunch

A containerized toolchain for data mining the game "Once Human."

## Legal

**DISCLAIMER**: Herein the term THE GAME shall refer to the Windows PC video game title "Once Human" and all assets it is composed of, which are the property of NetEase, Inc. The term THE TOOL collectively refers to the assets and methods which "Once Crunch" is composed of, which are not the property of NetEase, Inc. THE TOOL facilitates FAIR USE as defined under United States Copyright Law. THE TOOL does not circumvent copy protection that effectively controls access to THE GAME. THE TOOL does not modify the THE GAME. THE TOOL does not seek to reproduce, redistribute, monetize, nor damage THE GAME. THE TOOL is not itself composed of any assets of THE GAME which would be protected under United States Copyright Law.

**TERMS OF USE**: By retaining a copy of the THE TOOL you agree to release its creators and contributors of all liability, and you also agree to assume sole responsibility for any damages caused by your use, misuse, or inability to use THE TOOL. If you are unwilling or lawfully unable to agree with these terms you must immediately cease use of the THE TOOL and destroy all copies in your possession.

**LICENSE**: THE TOOL is released under the MIT LICENSE, and Copyright of any novel component or derivative work is held by its respective creator(s) and/or contributor(s). A copy of this license and the full terms of the license should have been received in a file named "LICENSE" when you received THE TOOL. Any reproduction or derivative of THE TOOL should include a copy of the MIT LICENSE, and relevant Copyright notices must be retained.

## Quick Start

### Prerequisites

- [Podman](https://podman.io/); a cross-platform tool that manages containers, pods, and images.
- [PowerShell](https://github.com/PowerShell/PowerShell); a cross-platform automation and configuration tool/framework.
- [Git](https://git-scm.com/); a free and open source distributed version control system.

### Storage

At the time of this writing, the game requires approximately 50GiB of storage. Once Crunch will consume an additional 150-450GiB of storage depending on how you use it.

### Containers

The creators of Once Crunch use `podman`, but you could adapt to using `docker`, `kubernetes`, `krunkit`, or any other OCI solution you prefer which is capable of running a container image **_interactively_**.

We do not publish a container image, you create an image yourself. You should not trust any published image identifying as Once Crunch. Full Stop.

### Installation

At this point you should have installed and configured prerequisites, confirming they work correctly, and you should have verified there is sufficient storage available to download a copy of the game.

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
# parent directory of the repo (not the repo
# directory) for storing files.
#
# if successful you should see a container shell.
#
# Once Crunch is ready for use.
#
```

### Game Files

Once Crunch does not contain a copy of the game. You will need to acquire the game through regular means. The container includes an installation of `steamcmd` which you could use, or, you could manually download and install the game.

#### Manual Installation/Copying

If you manually install/copy the game files you should know that Once Crunch expected the root of the game to be the directory `/data/once-human` inside of the container. Where this maps to outside of the container is something only you will know. If you followed the instructions above the "once-human" directory should exist side-by-side with the "once-crunch" directeory created by `git clone`.

#### Using `steamcmd`

To install using `steamcmd` there are two scripts you can use from inside the container. The first will auth you to Steam servers. The second will allow you to download the game from Steam servers after you have auth'd. 

Unfortunately, downloading the game via `steamcmd` requires a login, but, the game is free and you can create an account just for downloading if you prefer (a best practice, actually.)

```sh
#
# steam auth.
#
# from inside the container:
#
cd /root/code/once-crunch 
scripts/auth-steam youraccount@email.com
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
scripts/download-game.sh youraccount@email.com
#
# ... wait ...
#
ll /data/once-human
#
# you should see the game files
#
```

At this point you now how Once Crunch installed and the game files downloaded.

## Usage

Once Crunch provides scripts for:

- Processing game files, extracting game data (unpack-game)
- Constructing a hierarchical copy of the game data.
- Converting all textures into PNGs for further image processing.
- Stitching well-known files such as map tiles.
- ... and more.

Making use of Once Crunch is a matter of running one or more scripts and inspecting the results.

## Next Steps

You are encouraged to peruse the `scripts/` folder and read the header of each script. Every script is self-documenting, and if there are dependencies between scripts they will be clearly noted. To get started, have a look at `unpack-nxpk.ps1` and `apply-nxfn.ps1` scripts, they will get you started.

## Why?

For fun. Once Human is an engaging gaming experience, and this work benefits the gaming community, both game players and game publishers, by enhancing that experience through value-added technical resources that otherwise would not be possible (or, would exist with a much degraded level of quality which would reflect poorly on the game.)

## Conclusion

Keep in mind that with power comes responsibility. 

Just because you can legally ACCESS data does not mean you can legally USE data.

**Do not publish any data without first consulting a lawyer on FAIR USE, COPYRIGHT LAW, DMCA, and any local or international laws you may be subject to.**

Enjoy!