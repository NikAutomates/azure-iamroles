function New-PIMGroupSettingsRule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RolePolicyID,
        [Parameter(Mandatory = $true)]
        [string]$NotificationRecipients,
        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $headers = @{
        Authorization  = "Bearer $AccessToken"
        "Content-Type" = "application/json"
    }

    $expiration_body = @"
{
  "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule",
  "id": "Expiration_Admin_Eligibility",
  "isExpirationRequired": false,
  "maximumDuration": "P0D",
  "target": {
    "caller": "Admin",
    "operations": [ "All" ],
    "level": "Eligibility",
    "targetObjects": [],
    "inheritableSettings": [],
    "enforcedSettings": []
  }
}
"@

    Invoke-RestMethod `
        -Uri "https://graph.microsoft.com/v1.0/policies/roleManagementPolicies/$RolePolicyID/rules/Expiration_Admin_Eligibility" `
        -Method PATCH `
        -Headers $headers `
        -Body $expiration_body

    $enablement_body = @"
{
  "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule",
  "id": "Enablement_EndUser_Assignment",
  "enabledRules": [ "MultiFactorAuthentication", "Justification" ],
  "target": {
    "caller": "EndUser",
    "operations": [ "All" ],
    "level": "Assignment",
    "targetObjects": [],
    "inheritableSettings": [],
    "enforcedSettings": []
  }
}
"@

    Invoke-RestMethod `
        -Uri "https://graph.microsoft.com/v1.0/policies/roleManagementPolicies/$RolePolicyID/rules/Enablement_EndUser_Assignment" `
        -Method PATCH `
        -Headers $headers `
        -Body $enablement_body

    $notif_admin_admin_elig_body = @"
{
  "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
  "id": "Notification_Admin_Admin_Eligibility",
  "notificationType": "Email",
  "recipientType": "Admin",
  "notificationLevel": "All",
  "isDefaultRecipientsEnabled": true,
  "notificationRecipients": [ "$NotificationRecipients" ],
  "target": {
    "caller": "Admin",
    "operations": [ "All" ],
    "level": "Eligibility",
    "targetObjects": [],
    "inheritableSettings": [],
    "enforcedSettings": []
  }
}
"@

    Invoke-RestMethod `
        -Uri "https://graph.microsoft.com/v1.0/policies/roleManagementPolicies/$RolePolicyID/rules/Notification_Admin_Admin_Eligibility" `
        -Method PATCH `
        -Headers $headers `
        -Body $notif_admin_admin_elig_body

    $notif_admin_admin_assign_body = @"
{
  "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
  "id": "Notification_Admin_Admin_Assignment",
  "notificationType": "Email",
  "recipientType": "Admin",
  "notificationLevel": "All",
  "isDefaultRecipientsEnabled": true,
  "notificationRecipients": [ "$NotificationRecipients" ],
  "target": {
    "caller": "Admin",
    "operations": [ "All" ],
    "level": "Assignment",
    "targetObjects": [],
    "inheritableSettings": [],
    "enforcedSettings": []
  }
}
"@

    Invoke-RestMethod `
        -Uri "https://graph.microsoft.com/v1.0/policies/roleManagementPolicies/$RolePolicyID/rules/Notification_Admin_Admin_Assignment" `
        -Method PATCH `
        -Headers $headers `
        -Body $notif_admin_admin_assign_body

    $notif_admin_enduser_assign_body = @"
{
  "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
  "id": "Notification_Admin_EndUser_Assignment",
  "notificationType": "Email",
  "recipientType": "Admin",
  "notificationLevel": "All",
  "isDefaultRecipientsEnabled": true,
  "notificationRecipients": [ "$NotificationRecipients" ],
  "target": {
    "caller": "EndUser",
    "operations": [ "All" ],
    "level": "Assignment",
    "targetObjects": [],
    "inheritableSettings": [],
    "enforcedSettings": []
  }
}
"@

    Invoke-RestMethod `
        -Uri "https://graph.microsoft.com/v1.0/policies/roleManagementPolicies/$RolePolicyID/rules/Notification_Admin_EndUser_Assignment" `
        -Method PATCH `
        -Headers $headers `
        -Body $notif_admin_enduser_assign_body
}