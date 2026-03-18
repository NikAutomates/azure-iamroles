$Commands = @(Get-ChildItem -Path $PSScriptRoot\*.ps1)
foreach ($Function in @($Commands)) {
    . $Function.FullName
}