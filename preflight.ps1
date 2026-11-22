# For PowerShell on Windows. The pre-flight and the workshop are Bash scripts: this script does not run them,
# it says how to start them in Git Bash, and how to install Git Bash when it is missing.
#
#   .\preflight.cmd       from PowerShell or cmd: Windows blocks .ps1 files by default, preflight.cmd does not
#   .\preflight.ps1       where running scripts is allowed

$GitForWindows = 'https://git-scm.com/download/win'

# bash.exe of Git for Windows, or $null. Not C:\Windows\System32\bash.exe: that one starts WSL.
function Find-GitBash {
    $candidates = @()
    $git = Get-Command git.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($git) {
        # ...\Git\cmd\git.exe or ...\Git\mingw64\bin\git.exe
        $folder = Split-Path -Parent $git.Source
        $candidates += Join-Path $folder '..\bin\bash.exe'
        $candidates += Join-Path $folder '..\..\bin\bash.exe'
    }
    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA)) {
        if ($root) {
            $candidates += Join-Path $root 'Git\bin\bash.exe'
            $candidates += Join-Path $root 'Programs\Git\bin\bash.exe'
        }
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return (Resolve-Path -LiteralPath $candidate).Path }
    }
    return $null
}

# C:\Users\me\pre-flight -> /c/Users/me/pre-flight, the path as Git Bash writes it.
function ConvertTo-BashPath([string] $path) {
    if ($path -match '^([A-Za-z]):\\?(.*)$') {
        $path = '/' + $Matches[1].ToLower() + '/' + $Matches[2]
    }
    return $path -replace '\\', '/'
}

$folder = ConvertTo-BashPath $PSScriptRoot
Write-Host ''
Write-Host 'The pre-flight and the workshop run in Bash, not in PowerShell.'
Write-Host ''
if (Find-GitBash) {
    Write-Host 'Git Bash is installed. Open it (Start menu: "Git Bash"), then type:'
    Write-Host ''
    Write-Host "  cd '$folder'"
    Write-Host '  ./preflight.sh'
    Write-Host ''
    Write-Host 'Start Docker first, if it is not running yet.'
    exit 0
}
Write-Host 'Git Bash is not installed. It comes with Git for Windows:'
Write-Host ''
Write-Host "  1. Download Git for Windows from $GitForWindows and run the installer."
Write-Host '     Or, in PowerShell: winget install --id Git.Git -e --source winget'
Write-Host '  2. Keep the default options: they install Git Bash.'
Write-Host '  3. Open Git Bash (Start menu: "Git Bash"), then type:'
Write-Host ''
Write-Host "       cd '$folder'"
Write-Host '       ./preflight.sh'
Write-Host ''
Write-Host 'You can also use a WSL2 terminal instead of Git Bash.'
exit 1
