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
    Start-Sleep -Seconds 3
}
$ArgList = @(
    "run", 
    "--rm", 
    "-v", "$DataDir`:/data", 
    "-e", "DISPLAY=$(@([Net.DNS]::GetHostAddresses([Environment]::MachineName) | Where-Object { $_.AddressFamily -eq "InterNetwork" })[0].ToString()):0"
)

if ($NonInteractive.IsPresent) {
    $ArgList += "localhost/once-crunch:latest"
    Start-Process "podman" -ArgumentList $ArgList -NoNewWindow
} else {
    $ArgList += "-it"
    $ArgList += "localhost/once-crunch:latest"
    $ArgList += "/bin/tmux"
    Start-Process "podman" -ArgumentList $ArgList -NoNewWindow -Wait
}
