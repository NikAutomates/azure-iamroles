function Get-EntraPIMGroup {
  param (
    [CmdletBinding()]
    [Parameter(Mandatory = $true)]
    [string]$EntraGroupID,
    [CmdletBinding()]
    [Parameter(Mandatory = $false)]
    [switch]$EligibleAssignment,
    [CmdletBinding()]
    [Parameter(Mandatory = $false)]
    [switch]$ActiveAssignment,
    [Parameter(Mandatory = $true)]
    [string]$AccessToken
  ) 

  $pim_for_groups_assignment = (Invoke-GraphAPIRequest `
      -Uri "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentSchedules?`$filter=groupId eq '$($EntraGroupID)'" `
      -Method GET `
      -AccessToken $AccessToken)


  $pim_for_groups_eligibility = (Invoke-GraphAPIRequest `
      -Uri "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/eligibilitySchedules?`$filter=groupId eq '$($EntraGroupID)'" `
      -Method GET `
      -AccessToken $AccessToken).value

  if ($ActiveAssignment -eq $true) {
    return $pim_for_groups_assignment
  }
  elseif ($EligibleAssignment -eq $true) {
    return $pim_for_groups_eligibility
  }
  else {
    return $pim_for_groups_assignment, $pim_for_groups_eligibility

  }
}