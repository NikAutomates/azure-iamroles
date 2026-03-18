function New-PIMAzureRoleActiveAssignment {
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

  $azure_pim_role_active_assignment = @"
{
  "properties": {
    "principalId": "$($EntraGroupID)",
    "roleDefinitionId": "$($ResourceScopeID)/providers/Microsoft.Authorization/roleDefinitions/$($RoleID)",
    "requestType": "AdminAssign",
    "assignmentType": "Assigned",
    "justification": "Automated active assignment",
    "scheduleInfo": {
      "startDateTime": "$(Get-Date -Format o)",
      "expiration": {
        "type": "NoExpiration"
      }
    }
  }
}
"@

  $assignment_id = (New-Guid).Guid
  Start-Sleep -Seconds 10

  Invoke-RestMethod `
    -Uri "https://management.azure.com/$($ResourceScopeID)/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$($assignment_id)?api-version=2020-10-01" `
    -Headers $headers `
    -Method PUT `
    -Body $azure_pim_role_active_assignment `
    -ContentType "application/json"
}