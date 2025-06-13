# Core module details
@{RootModule = 'Reload.psm1'
ModuleVersion = '1.1'
GUID = 'e2c776e4-a2eb-49b3-8b1d-0bb480be9dc5'
Author = 'Schvenn'
CompanyName = 'Plath Consulting Incorporated'
Copyright = '(c) Craig Plath. All rights reserved.'
Description = 'Module, function and PowerShell environment reloader.'
CompatiblePSEditions = @('Desktop')
FunctionsToExport = @('reload')
PowerShellVersion = '5.1'
# Dependency
RequiredModules = @('findin')
# Configuration data
PrivateData = @{commonerrors = @('if \([\$\w\s:]+\s*=', '\x24_ \.', '\x24[\w\:]+: ')}}
