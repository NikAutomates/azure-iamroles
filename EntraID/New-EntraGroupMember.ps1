function New-EntraGroupMember {
  param (
    [CmdletBinding()]
    [Parameter(Mandatory = $true)]
    [string]$EntraGroupID,
    [CmdletBinding()]
    [Parameter(Mandatory = $true)]
    [string]$EntraUserID,
    [Parameter(Mandatory = $true)]
    [string]$AccessToken
  )

  begin {
   
    $new_entra_group_member = @"
{
  "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/$($EntraUserID)"
}
"@
  }
  process {
    $member_of = Invoke-GraphAPIRequest -Uri "https://graph.microsoft.com/v1.0/users/$($EntraUserID)/memberOf" -Method 'GET' -AccessToken $AccessToken

    if ($member_of.id -contains $EntraGroupID) {
      Write-Warning "$($EntraUserID) is already in group $($EntraGroupID)"
      return
    }
    
    Invoke-GraphAPIRequest `
      -Uri "https://graph.microsoft.com/v1.0/groups/$($EntraGroupID)/members/`$ref" `
      -Method POST `
      -Body $new_entra_group_member `
      -AccessToken $AccessToken
  }  
}