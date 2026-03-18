function New-EntraGroup {
  param (
    [CmdletBinding()]

    [Parameter(Mandatory = $true)]
    [string]$EntraGroupName,
    [Parameter(Mandatory = $true)]
    [string]$AccessToken,
    [Parameter(Mandatory = $false)]
    [string]$Description
  )
   

    $new_entra_group = @" 
{
  "displayName": "$($EntraGroupName)",
  "mailEnabled": false,
  "mailNickname": "$($EntraGroupName)",
  "description": "$($Description)",
  "securityEnabled": true
}
"@

    Invoke-GraphAPIRequest `
      -Uri "https://graph.microsoft.com/v1.0/groups" `
      -Method POST `
      -Body $new_entra_group `
      -AccessToken $AccessToken
}