#!/bin/pwsh
param(
    [switch]$IncludeSecureResources,
    [switch]$Force
)

# DISCLAIMER
# when i initially put all this together i
# was working on my gaming PC (windows) so
# i bootstrapped using pwsh. it will also
# work within linux and darwin, but i'm sure
# very few use it on all platforms despite
# it being a shell capable of everything a
# full programming language is capable of.

# you only need these if you plan on committing changes
# if you remove/omit or do not have these you also
# need to edit the Containerfile to not expect them.
#
# most people can just ignore these.
#
$context = $pwd.Path
if ([string]::IsNullOrWhiteSpace($env:HOME)) {
    $env:HOME = $env:USERPROFILE
}

if ($Force.IsPresent) {
    # these things only update if they do not already exist in the container context
    Remove-Item -Recurse -Force "$context/ssh" 2>&1 | Out-Null
    Remove-Item -Force "$context/git-signing-keys.gpg" 2>&1 | Out-Null
    Remove-Item -Force "$context/gitconfig" 2>&1 | Out-Null
    Remove-Item -Recurse -Force "$context/deps" 2>&1 | Out-Null
    # and sometimes i need to force the image itself to rebuild.
    podman image rm --force localhost/once-crunch 2>&1 | Out-Null
}

if ($IncludeSecureResources.IsPresent) {
    #
    # if you don't want these copied you obviously
    # should not pass `-IncludeSecureResources` switch
    # to script. they're only useful if you're doing
    # development inside the container.
    #
    if (![IO.Directory]::Exists("$context/ssh")) {
        if (![IO.Directory]::Exists("$env:HOME/.ssh")) {
            Write-Error "You forgot your ssh keys."
            return
        }
        Copy-Item -Recurse $env:HOME/.ssh $context/ssh
    }
    if (![IO.File]::Exists("$context/git-signing-keys.gpg")) {
        if (![IO.File]::Exists("$env:HOME/git-signing-keys.gpg")) {
            Write-Error "You forgot your signing keys."
            return
        }
        #
        # this file will ONLY exist if you've explicitly created it
        #
        Copy-Item "$env:HOME/git-signing-keys.gpg" $context/git-signing-keys.gpg
    }
    if (![IO.File]::Exists("$context/gitconfig")) {
        if (![IO.File]::Exists("$env:HOME/.gitconfig")) {
            Write-Error "You forgot your global git config."
            return
        }
        # this file for commit signing and author info,
        # since i do all my development inside the container i need this
        #
        # you can, obviously, point this at a custom config
        # or `touch gitconfig` before running this script to not copy yours in.
        #
        Copy-Item $env:HOME/.gitconfig $context/gitconfig
    }
} else {
    # if present, empty ~/.ssh will be created, which is fine
    mkdir -p "$context/ssh" 2>&1 | Out-Null
    echo "" > "$context/ssh/not-configured"
    # if empty, git will not care and will still work
    echo "" > "$context/gitconfig"
    # if empty, gnupg will not be called to import during container creation
    echo "" > "$context/git-signing-keys.gpg"
}
# this is a required third-party dependency. download
# it yourself and make sure the name here matches
# your downloaded filename. i only tested with "2024_R1"
#
# https://developer.imaginationtech.com/downloads/
#
mkdir -p "$context/deps" 2>&1 | Out-Null
if (![IO.File]::Exists("$context/deps/PVRTexToolSetup")) {
    if (![IO.File]::Exists("$env:HOME/Downloads/PVRTexToolSetup-2024_R1.run-x64")) {
        Write-Error "Setup file for PVRTexTool not found."
        Write-Error "Download from: https://developer.imaginationtech.com/downloads/"
        Write-Error "Copy into $HOME/Downloads with name: PVRTexToolSetup-2024_R1.run-x64"
        return
    }
    Copy-item "$env:HOME/Downloads/PVRTexToolSetup-2024_R1.run-x64" "$context/deps/PVRTexToolSetup"
}

# build the container
$once_crunch_remote = $(git remote get-url origin) # avoiding a hardcode
$quickbms_remote = $once_crunch_remote.Replace("once-crunch", "quickbms") # avoiding a hardcode
Start-Process -NoNewWindow -Wait -FilePath "podman" -ArgumentList @(
    "build",
    "--arch", "amd64",
    "--os", "linux",
    "--build-arg", "ONCE_CRUNCH_REMOTE=$once_crunch_remote",
    "--build-arg", "QUICKBMS_REMOTE=$quickbms_remote",
    "-t", "once-crunch",
    "$context")
