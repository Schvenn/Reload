function reload ([string]$command) {# Reload a Module or the PowerShell environment.

function usage {Write-Host -f cyan "`nUsage: Reload (PowerShell/Clear/ModuleName)`n"; return}

# Error-checking.
if (-not $command -or $command.length -le 1) {usage; return}

# Reload PowerShell.
if ($command -match "(?i)^powershell$") {Start-Process pwsh -ArgumentList "-NoExit"; exit}

# Clear-History and restart Powershell.
if ($command -match "(?i)^clear$") {if (Test-Path "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt") {Remove-Item $historyFile -Force}; cmd /c "pwsh -NoExit"; clear-history; clear-content $goodhistory; exit}

# Reload Function.
if ($command -match "(?i)^f(unctio)?n:([\w-]+)$") {$funcName = $matches[2]
$func = Get-Command $funcName -CommandType Function -ErrorAction SilentlyContinue; if (-not $func) {return}
$mod = $func.Module; if (-not $mod) {return}

Remove-Item Function:$funcName -ErrorAction SilentlyContinue; if ($?) {Write-Host -f yellow "`nRemoved function: " -NoNewLine; Write-Host -f white "$funcName"}
else {Write-Host -f red "`nFailed to remove function " -NoNewLine; Write-Host -f white "$funcName"}

Import-Module $mod.Name -Force -ErrorAction SilentlyContinue; if ($?) {Write-Host -f green "Reloaded module: " -NoNewLine; Write-Host -f white $mod}
else {Write-Host -f red "Failed to import module " -NoNewLine; Write-Host -f white ($mod.name).ToUpper()}; ""; return}

# Error-checking.
if (-not (Get-Module $command -ErrorAction SilentlyContinue)) {usage; return}

# Reload a module.
""; (Get-Command -Module $command -ErrorAction SilentlyContinue).ForEach{Remove-Item Function:$_ -Force; if ($?) {Write-Host -f yellow "Removed function: " -NoNewLine; Write-Host -f white "$_"}
else {Write-Host -f red "Failed to remove function " -NoNewLine; Write-Host -f white "$_"}}

Remove-Module $command -Force -ErrorAction SilentlyContinue
if ($?) {Write-Host -f yellow "`nRemoved module: " -NoNewLine; Write-Host -f white $command.ToUpper()}
else {Write-Host -f red "`nFailed to remove module " -NoNewLine; Write-Host -f white "$command"}

ipmo $command -Force -ErrorAction SilentlyContinue
if ($?) {Write-Host -f green "Reloaded module: " -NoNewLine; Write-Host -f white $command.ToUpper(); ""}
else {Write-Host -f red "Failed to import module " -NoNewLine; Write-Host -f white $command.ToUpper(); ""}}

Export-ModuleMember -Function reload

<#
## Reload

Reload PowerShell: This will restart an instane of PowerShell, but maintain history.

Reload Clear: This will forcibly erase the command history and restart PowerShell.

Reload <Function/Fn:FunctionName>: This will remove a single function and reload the module in which it resides.

Reload <ModuleName>: This will clear all functions of a module, remove and reload the module.
##>
