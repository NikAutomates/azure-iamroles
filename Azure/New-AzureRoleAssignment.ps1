function New-AzureRoleAssignment {
  param (
    [Parameter(Mandatory = $true)]
    [string]$EntraGroupID,
    [Parameter(Mandatory = $true)]
    [string]$ResourceScopeID,
    [Parameter(Mandatory = $true)]
    [string]$RoleID,
    [Parameter(Mandatory = $true)]
    [string]$AccessToken
  )

  $headers = @{
    Authorization  = "Bearer $($AccessToken)"
    "Content-Type" = "application/json"
  }

  $body = @"
{
  "properties": {
    "principalId": "$($EntraGroupID)",
    "roleDefinitionId": "$($ResourceScopeID)/providers/Microsoft.Authorization/roleDefinitions/$($RoleID)"
  }
}
"@

  $assignment_id = (New-Guid).Guid

  Invoke-RestMethod `
    -Uri "https://management.azure.com/$($ResourceScopeID)/providers/Microsoft.Authorization/roleAssignments/$($assignment_id)?api-version=2022-04-01" `
    -Headers $headers `
    -Method PUT `
    -Body $body `
    -ContentType "application/json"
}
