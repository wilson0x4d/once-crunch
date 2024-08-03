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
    $context = $pwd.Path
    $DataDir = [IO.Path]::GetFullPath("$context/..")
}
if ($NonInteractive.IsPresent) {
    podman run --rm -it -v "$DataDir`:/data" once-crunch
} else {
    podman run --rm -it -v "$DataDir`:/data" once-crunch "/bin/tmux"
}
