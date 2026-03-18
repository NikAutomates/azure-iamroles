function Get-PIMAzureRoleEligibleAssignment {
  param (
    [Parameter(Mandatory = $true)]
    [string]$EntraGroupID,
    [Parameter(Mandatory = $false)]
    [string]$ResourceScopeID,
    [Parameter(Mandatory = $true)]
    [string]$RoleDefinitionID,
    [Parameter(Mandatory = $true)]
    [string]$AccessToken
  )

  $headers = @{
    Authorization  = "Bearer $($AccessToken)" 
    "Content-Type" = "application/json"
  }

  //todo 
  (Invoke-RestMethod `
    -Uri "https://management.azure.com/$($ResourceScopeID)/providers/Microsoft.Authorization/roleEligibilitySchedules?api-version=2020-10-01" `
    -Headers $headers `
    -Method GET).value.properties | Where-Object { $_.principalId -eq $EntraGroupID -and $_.roleDefinitionId.Split("roleDefinitions/")[1] -eq $RoleDefinitionID }

}
