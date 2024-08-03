#!/bin/pwsh
param(
    [parameter()]
    [switch]$NonInteractive,
    [parameter()]
    [string]$DataDir,
    [parameter()]
    [string]$LaunchTarget = "/bin/tmux"
)
if ([String]::IsNullOrWhiteSpace($DataDir)) {
    # when not specified the datadir defaults to the
    # directory just above the git repo. this is a
    # personal convenience so i can access the 
    # repo from within the container (rather than)
    # the ephemeral snapshot pulled during container
    # creation.
    $context = $pwd.Path
    $DataDir = [IO.Path]::GetFullPath("$context/..")
    Write-Warning "You did not provide a -DataDir argument.`nThe data directory is defaulted to: `n$DataDir"
    Start-Sleep -Seconds 5
}
if ($NonInteractive.IsPresent) {
    podman run --rm -it -v "$DataDir`:/data" localhost/once-crunch:latest
} else {
    podman run --rm -it -v "$DataDir`:/data" localhost/once-crunch:latest /bin/tmux
}
