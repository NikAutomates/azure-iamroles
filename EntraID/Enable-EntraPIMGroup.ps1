function Enable-EntraPIMGroup {
  param (
    [CmdletBinding()]
    [Parameter(Mandatory = $true)]
    [string]$EntraGroupID,
    [Parameter(Mandatory = $true)]
    [string]$PIMActivationGroupID,
    [Parameter(Mandatory = $true)]
    [string]$AccessToken
  )

  $startTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  $enable_pim_for_groups = @"
{
  "accessId": "member",
  "principalId": "$($PIMActivationGroupID)",
  "groupId": "$($EntraGroupID)",
  "action": "adminAssign",
  "scheduleInfo": {
    "startDateTime": "$startTime",
    "expiration": {
      "type": "afterDuration",
      "duration": "PT5M"
    }
  },
  "justification": "Temporary 5-minute assignment of dummy group to enable PIM for Groups"
}
"@
  Invoke-GraphAPIRequest `
    -Uri "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests" `
    -Method POST `
    -Body $enable_pim_for_groups `
    -AccessToken $AccessToken

}