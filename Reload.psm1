function reload ($command, [switch]$help) {# Reload a Module or the PowerShell environment.
$script:powershell = Split-Path $profile; $basemodulepath = Join-Path $script:powershell "Modules\Reload"; $script:configpath = Join-Path $basemodulepath "Reload.psd1"

# Modify fields sent to it with proper word wrapping.
function wordwrap ($field, $maximumlinelength) {if ($null -eq $field) {return $null}
$breakchars = ',.;?!\/ '; $wrapped = @()
if (-not $maximumlinelength) {[int]$maximumlinelength = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($maximumlinelength -lt 60) {[int]$maximumlinelength = 60}
if ($maximumlinelength -gt $Host.UI.RawUI.BufferSize.Width) {[int]$maximumlinelength = $Host.UI.RawUI.BufferSize.Width}
foreach ($line in $field -split "`n", [System.StringSplitOptions]::None) {if ($line -eq "") {$wrapped += ""; continue}
$remaining = $line
while ($remaining.Length -gt $maximumlinelength) {$segment = $remaining.Substring(0, $maximumlinelength); $breakIndex = -1
foreach ($char in $breakchars.ToCharArray()) {$index = $segment.LastIndexOf($char)
if ($index -gt $breakIndex) {$breakIndex = $index}}
if ($breakIndex -lt 0) {$breakIndex = $maximumlinelength - 1}
$chunk = $segment.Substring(0, $breakIndex + 1); $wrapped += $chunk; $remaining = $remaining.Substring($breakIndex + 1)}
if ($remaining.Length -gt 0 -or $line -eq "") {$wrapped += $remaining}}
return ($wrapped -join "`n")}

if ($help) {# Inline help.
function scripthelp ($section) {# (Internal) Generate the help sections from the comments section of the script.
""; Write-Host -f yellow ("-" * 100); $pattern = "(?ims)^## ($section.*?)(##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $lines = $match.Groups[1].Value.TrimEnd() -split "`r?`n", 2; Write-Host $lines[0] -f yellow; Write-Host -f yellow ("-" * 100)
if ($lines.Count -gt 1) {wordwrap $lines[1] 100| Out-String | Out-Host -Paging}; Write-Host -f yellow ("-" * 100)}
$scripthelp = Get-Content -Raw -Path $PSCommandPath; $sections = [regex]::Matches($scripthelp, "(?im)^## (.+?)(?=\r?\n)")
if ($sections.Count -eq 1) {cls; Write-Host "$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)) Help:" -f cyan; scripthelp $sections[0].Groups[1].Value; ""; return}

$selection = $null
do {cls; Write-Host "$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)) Help Sections:`n" -f cyan; for ($i = 0; $i -lt $sections.Count; $i++) {
"{0}: {1}" -f ($i + 1), $sections[$i].Groups[1].Value}
if ($selection) {scripthelp $sections[$selection - 1].Groups[1].Value}
$input = Read-Host "`nEnter a section number to view"
if ($input -match '^\d+$') {$index = [int]$input
if ($index -ge 1 -and $index -le $sections.Count) {$selection = $index}
else {$selection = $null}} else {""; return}}
while ($true); return}

if (!(Test-Path $script:configpath)) {throw "Config file not found at $script:configpath"}
$config = Import-PowerShellDataFile -Path $configpath
$script:commonerrors = $config.PrivateData.commonerrors

$instance=Split-Path -Leaf (Get-Process -Id $PID).Path

function usage {Write-Host -f cyan "`nUsage: Reload (PowerShell/Pwsh/Clear/ModuleName)`n"; return}

# Error-checking.
if ($command.length -le 1) {usage; return}

# Reload PowerShell.
if ($command -match "(?i)^p(owershell|wsh)$") {Start-Process $instance -ArgumentList "-NoExit"; exit}

# Clear-History and restart Powershell.
if ($command -match "(?i)^clear$") {if (Test-Path "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt") {Remove-Item $historyFile -Force}; cmd /c "$instance -NoExit"; clear-history; clear-content $goodhistory; exit}

# Reload Function.
if ($command -match "(?i)^f(unctio)?n:([\w-]+)$") {$funcName = $matches[2]
$func = Get-Command $funcName -CommandType Function -ErrorAction SilentlyContinue; if (-not $func) {return}
$mod = $func.Module; if (-not $mod) {return}

Remove-Item Function:$funcName -ErrorAction SilentlyContinue; if ($?) {Write-Host -f yellow "`nRemoved function: " -n; Write-Host -f white "$funcName"}
else {Write-Host -f red "`nFailed to remove function " -n; Write-Host -f white "$funcName"}

Import-Module $mod.Name -Force -ErrorAction SilentlyContinue; if ($?) {Write-Host -f green "Reloaded module: " -n; Write-Host -f white $mod}
else {Write-Host -f red "Failed to import module " -n; Write-Host -f white ($mod.name).ToUpper()}; ""; return}

# Try to load the module if it's not already loaded.
if (-not (Get-Module $command -ErrorAction SilentlyContinue)) {try {ipmo $command -ErrorAction Stop; Write-Host -f green "`nLoaded module: " -n; Write-Host -f white $command.ToUpper()} catch {Write-Host -f white "`nFailed to import module: " -n; Write-Host -f red ($command).ToUpper(); Write-Host -f yellow ("-" * 100); $result = "$_.Exception.Message"; Write-Host -f white "`n$($result.substring(120))`n"; Write-Host -f yellow ("-" * 100)}; ""; return}

# Reload a module.
""; (Get-Command -Module $command -ErrorAction SilentlyContinue).ForEach{Remove-Item Function:$_ -Force; if ($?) {Write-Host -f yellow "Removed function: " -n; Write-Host -f white "$_"}
else {Write-Host -f red "Failed to remove function " -n; Write-Host -f white "$_"}}

# Warn of the most common logic errors.
if (Get-Command findin -ErrorAction SilentlyContinue) {Write-Host -f yellow "`nSearching for common PowerShell errors inside '$command':"; $current = Get-Location; sl $powershell; $pattern = '(?i)' + ($script:commonerrors -join '|'); findin "$command.psm1" $pattern -recurse; sl $current}

Remove-Module $command -Force -ErrorAction SilentlyContinue
if ($?) {Write-Host -f yellow "`nRemoved module: " -n; Write-Host -f white $command.ToUpper()}
else {Write-Host -f red "`nFailed to remove module " -n; Write-Host -f white "$command"}

ipmo $command -Force -ErrorAction SilentlyContinue
if ($?) {Write-Host -f green "Reloaded module: " -n; Write-Host -f white $command.ToUpper(); ""}
else {Write-Host -f red "Failed to import module: " -n; Write-Host -f white ($command).ToUpper(); ""}}

Export-ModuleMember -Function reload

<#
## Reload

Reload PowerShell/Pwsh: This will restart the current instance of PowerShell, but maintain history.

Reload Clear: This will forcibly erase the command history and restart the current instance of PowerShell.

Reload <Function/Fn:FunctionName>: This will remove a single function and reload the module in which it resides.

Reload <ModuleName>: This will clear all functions of a module, remove and reload the module.
## License
MIT License

Copyright © 2025 Craig Plath

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
THE SOFTWARE.
##>
