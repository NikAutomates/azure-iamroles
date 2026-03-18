

function New-PIMForGroupsEligibleAssignment {
  param (
    [Parameter(Mandatory = $true)]
    [string]$EntraGroupID,    
    [Parameter(Mandatory = $true)]
    [string]$PrincipalID,      
    [Parameter(Mandatory = $true)]
    [string]$AccessToken
  )
  $pim_for_groups_group_eligible_member_assignment = @"
{
  "accessId": "member",
  "principalId": "$($PrincipalID)",
  "groupId": "$($EntraGroupID)",
  "action": "adminAssign",
  "scheduleInfo": {
    "startDateTime": "$(Get-Date -Format o)",
    "expiration": {
      "type": "NoExpiration"
    }
  },
  "justification": "Permanent eligible assignment"
}
"@
  Invoke-GraphAPIRequest `
    -Uri "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/eligibilityScheduleRequests" `
    -Method POST `
    -Body $pim_for_groups_group_eligible_member_assignment `
    -AccessToken $AccessToken
}