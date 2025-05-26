function reload ([string]$command) {# Reload a Module or the PowerShell environment.
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
##>
