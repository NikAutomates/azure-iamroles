function Get-AzureRoleGUID {
  param (
    [Parameter(Mandatory = $false)]
    [string]$RoleName,
    [Parameter(Mandatory = $false)]
    [string]$AccessToken
  ) 

  $headers = @{
    Authorization  = "Bearer $($AccessToken)"
    "Content-Type" = "application/json"
  }

  $roles_and_guids_uri = "https://management.azure.com/providers/Microsoft.Authorization/roleDefinitions?api-version=2022-04-01"
  return $((Invoke-RestMethod -Method 'GET' -Uri $roles_and_guids_uri -Headers $headers).value | Where-Object { $_.properties.RoleName -eq $($RoleName) }).name

}