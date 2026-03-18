function New-PIMAzureRoleSettingsRule {
  param (
    [Parameter(Mandatory = $true)]
    [string]$NotificationRecipients,
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
  $pim_role_rule_settings = $pim_role_rule_settings = @"
{
  "properties": {
    "rules": [
      {
        "id": "Expiration_Admin_Eligibility",
        "ruleType": "RoleManagementPolicyExpirationRule",
        "isExpirationRequired": false,
        "maximumDuration": "P0D",
        "target": {
          "caller": "Admin",
          "operations": [ "All" ],
          "level": "Eligibility"
        }
      },
      {
        "id": "Expiration_Admin_Assignment",
        "ruleType": "RoleManagementPolicyExpirationRule",
        "isExpirationRequired": false,
        "maximumDuration": "P0D",
        "target": {
          "caller": "Admin",
          "operations": [ "All" ],
          "level": "Assignment"
        }
      },
      {
        "enabledRules": [
          "MultiFactorAuthentication",
          "Justification"
        ],
        "id": "Enablement_EndUser_Assignment",
        "ruleType": "RoleManagementPolicyEnablementRule",
        "target": {
          "caller": "EndUser",
          "operations": [ "All" ],
          "level": "Assignment"
        }
      },
      {
        "notificationType": "Email",
        "recipientType": "Admin",
        "isDefaultRecipientsEnabled": true,
        "notificationLevel": "All",
        "notificationRecipients": [
          "$($NotificationRecipients)"
        ],
        "id": "Notification_Admin_Admin_Assignment",
        "ruleType": "RoleManagementPolicyNotificationRule",
        "target": {
          "caller": "Admin",
          "operations": [ "All" ],
          "level": "Assignment"
        }
      }
    ]
  }
}
"@
  Invoke-RestMethod -Uri "https://management.azure.com/$($ResourceScopeID)/providers/Microsoft.Authorization/roleManagementPolicies/$($RoleID)?api-version=2020-10-01" `
    -Headers $headers `
    -Method 'PATCH' `
    -Body $pim_role_rule_settings
}