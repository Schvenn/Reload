@{RootModule = 'Reload.psm1'
ModuleVersion = '1.1'
GUID = '123708bd-12d7-4866-950c-2c8b22357d96'
Author = 'Craig Plath'
CompanyName = 'Plath Consulting Incorporated'
Copyright = '© Craig Plath. All rights reserved.'
Description = 'PowerShell module to restart PowerShell, or reloads functions and modules, individually.'
PowerShellVersion = '5.1'
FunctionsToExport = @('Reload')
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()
FileList = @('Reload.psm1')

PrivateData = @{PSData = @{Tags = @('function', 'module', 'development', 'restart', 'reload', 'initialize', 'powershell')
LicenseUri = 'https://github.com/Schvenn/Reload/blob/main/LICENSE'
ProjectUri = 'https://github.com/Schvenn/Reload'
ReleaseNotes = 'Addition of FindIn Regex matches for common errors.'}

commonerrors = 'if \([\$\w\s:]+\s*=', '\x24_ \.', '\x24[\w\:]+: '}}
