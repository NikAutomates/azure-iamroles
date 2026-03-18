param(

    [string]$graph_token,
    [string]$azure_token
) 


$hash = @{
  azapi    = "https://management.azure.com/"
  graphapi = "https://graph.microsoft.com/"
}
$tokenResponse = Get-AzAccessToken -ResourceUrl $hash.azapi
$secureToken = $tokenResponse.Token
$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
$azure_token = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)

#Import-Module (Join-Path $PSScriptRoot "../modules/entra_azure.psm1") -Force

$headers = @{
    Authorization  = "Bearer $($azure_token)"
    "Content-Type" = "application/json"
}

<#function New-AzureIAMRoleAssignment {
    param (
        [Parameter(Mandatory)]
        [array]$lookup_table
    ) #>

$lookup_table = @(

    @{
        RoleName     = "Contributor"
        ResourceName = "terraform"
        UsePIM       = $false
        Members      = @("nik.chikersal@azurecloudsecurity.com")
    }
)

    foreach ($item in $lookup_table) {

        $found_resource = $null
        $subscription_id = $null

        Write-Host "Resolving scope for $($item.ResourceName)" -ForegroundColor Cyan

      $mg = (Invoke-RestMethod `
                -Uri "https://management.azure.com/providers/Microsoft.Management/managementGroups?api-version=2021-04-01" `
                -Method GET `
                -Headers $headers).value

        $mg_match = $mg | Where-Object { $_.name -eq $item.ResourceName -or $_.properties.displayName -eq $item.ResourceName }

        if ($mg_match) {
            $found_resource = "/providers/Microsoft.Management/managementGroups/$($mg_match.name)"
        }

        if (-not $found_resource) {
            $subs = (Invoke-RestMethod `
                    -Uri "https://management.azure.com/subscriptions?api-version=2020-01-01" `
                    -Method GET `
                    -Headers $headers).value

            $sub_match = $subs | Where-Object { $_.displayName -eq $item.ResourceName -or $_.subscriptionId -eq $item.ResourceName }

            if ($sub_match) {
                $found_resource = "/subscriptions/$($sub_match.subscriptionId)"
            }
        }
        if (-not $found_resource) {

            $rg_query = @"
{
    "query": "ResourceContainers | where type == 'microsoft.resources/subscriptions/resourcegroups' and name =~ '$($item.ResourceName)' | project id"
}
"@

            $rg_result = (Invoke-RestMethod `
                    -Uri "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01" `
                    -Method POST `
                    -Headers $headers `
                    -Body $rg_query).data

            if ($rg_result.Count -eq 1) {
                $found_resource = $rg_result[0].id
            }
            elseif ($rg_result.Count -gt 1) {
                throw "Multiple resource groups named '$($item.ResourceName)' found. Ambiguous. Stopping."
            }
        }

        if (-not $found_resource) {

            $resource_query = @"
{
    "query": "Resources | where name =~ '$($item.ResourceName)' | project id"
}
"@

            $resource_result = (Invoke-RestMethod `
                    -Uri "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01" `
                    -Method POST `
                    -Headers $headers `
                    -Body $resource_query).data

            if ($resource_result.Count -eq 1) {
                $found_resource = $resource_result[0].id
            }
            elseif ($resource_result.Count -gt 1) {
                throw "Multiple resources named '$($item.ResourceName)' found. Ambiguous. Stopping."
            }
        }

        if (-not $found_resource) {
            throw "Scope '$($item.ResourceName)' not found as management group, subscription, resource group, or resource. Stopping."
        }

        Write-Host "Resolved scope: $found_resource" -ForegroundColor Green


    
        switch ($item.UsePIM) {
            #IF PIM Group block
            $true {
                $group_name = "sec-pim-" + $item.ResourceName + "-" + $item.RoleName.Replace(" ", "-").ToLower()
                $group_exists = (Invoke-GraphAPIRequest -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$($group_name)'" -Method GET -AccessToken $graph_token)

                #if group exists, add members to eligible assignment
                if ($group_exists.id ) { 
                    foreach ($member in $item.Members) {
                        $user_object_id = (Invoke-GraphAPIRequest -Uri "https://graph.microsoft.com/v1.0/users?`$filter=userprincipalname eq '$($member)'" -Method GET -AccessToken $graph_token).value
                
                        #check if user already has eligible assignment to group
                        $existing_entra_group_id = ([string]$group_exists.id).Trim()
                        $existing_user_object_id = ([string]$user_object_id.id).Trim()
                        $existing_eligible_assignment = (Invoke-GraphAPIRequest `
                                -Uri "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/eligibilityScheduleInstances?`$filter=groupId eq '$($existing_entra_group_id)'" `
                                -Method GET `
                                -AccessToken $graph_token).principalId -contains $existing_user_object_id
  
                        if ($existing_eligible_assignment -eq $false) {
                            #set eligible assignment for user to existing PIM Group

                            Write-Host "Assigning user $($member) as an eligible assignment to PIM Group $($new_entra_group.displayName)" -ForegroundColor Green
                            New-PIMForGroupsEligibleAssignment -EntraGroupID $existing_entra_group_id -PrincipalID $existing_user_object_id -AccessToken $graph_token -Verbose
                        }
                        else {
                            Write-Warning "User $($member) already has an eligible assignment to group $($group_name)"
                        }
                    }
                }
                elseif (-not ($group_exists.id)) {
                    #create PIM group
                    $new_entra_group = New-EntraGroup -EntraGroupName $group_name -Description "Grants the on $($item.RoleName) Role on the Resource $($item.ResourceName)" -AccessToken $graph_token
                    Start-Sleep -Seconds 10
                    if ($new_entra_group) {
                        #enable PIM For groups on new group
                        Write-Host "Enabling PIM for Groups on $($new_entra_group.displayName)" -ForegroundColor Green
                        Enable-EntraPIMGroup -EntraGroupID $new_entra_group.id -PIMActivationGroupID 'b74dfcb8-2a55-404f-ad45-00c14307e286' -AccessToken $graph_token | Out-Null

                        Write-Host "Creating PIM policy settings for $($new_entra_group.displayName)" -ForegroundColor Green

                        #New PIM policy settings on the Azure Role
                        New-PIMAzureRoleSettingsRule -NotificationRecipients "test@pim.com" -RoleID $(Get-AzureRoleGUID -RoleName $item.RoleName -AccessToken $azure_token) -ResourceScopeID $found_resource -AccessToken $azure_token | Out-Null

                        Write-Host "Assigning $($new_entra_group.displayName) as an active assignment to Azure Role $($item.RoleName) on resource $($item.ResourceName)" -ForegroundColor Green
                        #assign the PIM entra group as an active assignment on the Azure PIM Role
                        New-PIMAzureRoleActiveAssignment -EntraGroupID $new_entra_group.id -ResourceScopeID $found_resource -RoleID $(Get-AzureRoleGUID -RoleName $item.RoleName -AccessToken $azure_token) -AccessToken $azure_token | Out-Null
                    
                        Write-Host "Retrieving PIM policy IDs for $($new_entra_group.displayName)" -ForegroundColor Green
                        #get owner and member policy IDs 
                        $pim_group_policy_ids = (Invoke-GraphAPIRequest `
                                -Uri "https://graph.microsoft.com/v1.0/policies/roleManagementPolicies?`$filter=scopeId eq '$($new_entra_group.id)' and scopeType eq 'Group'" `
                                -Method GET `
                                -AccessToken $graph_token).id 
                            

                        foreach ($pim_group_policy_id in $pim_group_policy_ids) {
                            #New PIM policy settings on the PIM Entra Group
                    
                            Write-Host "Creating PIM policy settings for $($new_entra_group.displayName)" -ForegroundColor Green

                            
                            New-PIMGroupSettingsRule -RolePolicyID $pim_group_policy_id -NotificationRecipients "pim@test.com" -AccessToken $graph_token | Out-Null

                        }
                    
                        foreach ($member in $item.Members) {
                            $user_object_id = (Invoke-GraphAPIRequest -Uri "https://graph.microsoft.com/v1.0/users?`$filter=userprincipalname eq '$($member)'" -Method GET -AccessToken $graph_token).value.id
                    
                            for ($i = 1; $i -le 5; $i++) {
                                try {
                                    Write-Host "Assigning user $($member) as an eligible assignment to PIM Group $($new_entra_group.displayName)" -ForegroundColor Green
                                    New-PIMForGroupsEligibleAssignment `
                                        -EntraGroupID $new_entra_group.id `
                                        -PrincipalID $user_object_id `
                                        -AccessToken $graph_token `
                                        -ErrorAction Stop | Out-Null
                                    break
                                }
                                catch {
                                    Write-Warning "Eligible assignment failed (attempt $i). Retrying in 5s..."
                                    Start-Sleep -Seconds 5
                                }
                            }
                        }
                    }
                }
            } 
            $false {
                Write-Host "UsePIM set to false for $($item.ResourceName). Proceeding with direct assignment" -ForegroundColor Cyan
                $group_name = "sec-" + $item.ResourceName + "-" + $item.RoleName.Replace(" ", "-").ToLower()
                $group_exists = (Invoke-GraphAPIRequest -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$($group_name)'" -Method GET -AccessToken $graph_token).value

                #if group exists, add members to group
                if ($group_exists.id) {
                    Write-Host "Group $($group_name) already exists. Adding members to group" -ForegroundColor Green
                    $existing_entra_group_id = ([string]$group_exists.id).Trim()
                    foreach ($upn in $item.Members) {
                        $user_object_id = [string](Invoke-GraphAPIRequest -Uri "https://graph.microsoft.com/v1.0/users?`$filter=userprincipalname eq '$($upn)'" -Method GET -AccessToken $graph_token).id
                        Start-Sleep -Seconds 5 #sleep to mitigate potential bad request when member is already in group even though function checks that
                        New-EntraGroupMember -EntraGroupID $existing_entra_group_id.Trim() -EntraUserID $user_object_id.Trim() -AccessToken $graph_token
                        Write-Host "Adding user $($upn) to group $($group_name)" -ForegroundColor Green
               
                    }
                }
                elseif (-not ($group_exists.id)) {
                    #create PIM group

                    $group_name = $group_name.ToString().Trim()

                    $new_entra_group = New-EntraGroup -EntraGroupName $group_name -Description "Grants the on $($item.RoleName) Role on the Resource $($item.ResourceName)" -AccessToken $graph_token
                    Start-Sleep -Seconds 15

                    #assign the entra group as a direct assignment on the Azure Role
                    if ($new_entra_group) {
                        foreach ($upn in $item.Members) {
                            $user_object_id = [string](Invoke-GraphAPIRequest -Uri "https://graph.microsoft.com/v1.0/users?`$filter=userprincipalname eq '$($upn)'" -Method GET -AccessToken $graph_token).id
                            New-EntraGroupMember -EntraGroupID $new_entra_group.id -EntraUserID $user_object_id.Trim() -AccessToken $graph_token
                        
                            Write-Host "Adding user $($upn) to group $($new_entra_group.displayName)" -ForegroundColor Green
                        }

                        #assign the entra group as a direct assignment on the Azure Role
                        Start-Sleep -Seconds 15 #sleep added to mitigate potential timing issue with group creation and assignment
                        New-AzureRoleAssignment -EntraGroupID $new_entra_group.id -RoleID $(Get-AzureRoleGUID -RoleName $item.RoleName -AccessToken $azure_token) -ResourceScopeID $found_resource -AccessToken $azure_token | Out-Null
                        Write-Host "Assigning $($new_entra_group.displayName) as a direct assignment to Azure Role $($item.RoleName) on resource $($found_resource)" -ForegroundColor Green

                    }
                }
            }
        }
    }
#}

#New-AzureIAMRoleAssignment -lookup_table $lookup_table