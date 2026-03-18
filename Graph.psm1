function Invoke-GraphAPIRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ArgumentCompleter({
                param(
                    [string]$commandName,
                    [string]$parameterName,
                    [string]$wordToComplete,
                    [System.Management.Automation.Language.CommandAst]$commandAst,
                    [System.Collections.IDictionary]$fakeBoundParameters
                )

                [array]$GraphURLs = [System.Collections.Generic.List[object]](
                    'https://graph.microsoft.com/v1.0/users',
                    'https://graph.microsoft.com/v1.0/groups'
                )

                $ArgCompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
                foreach ($Url in $GraphURLs) {
                    if ($Url -like "$wordToComplete*") {
                        [void]$ArgCompletionResults.Add(
                            [System.Management.Automation.CompletionResult]::new($Url, $Url, 'ParameterValue', $Url)
                        )
                    }
                }
             return $ArgCompletionResults
         })]
        [ValidatePattern('^https?')]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,
        [Parameter(Mandatory = $true, ValueFromPipeline = [boolean]$true, ValueFromPipelineByPropertyName = [boolean]$true)]
        [ValidateSet("GET", "DELETE", "POST", "PATCH", "PUT")][ValidateNotNullOrEmpty()]
        [string]$Method,
        [Parameter(Mandatory = $false, ValueFromPipeline = [boolean]$true, ValueFromPipelineByPropertyName = [boolean]$true)]
        [string]$Body,
        [Parameter(Mandatory = $false, ValueFromPipeline = [boolean]$true, ValueFromPipelineByPropertyName = [boolean]$true)]
        [string]$AccessToken,
        [Parameter(Mandatory = $false)]
        [hashtable]$Headers
    )
    
    begin {
       
        $global:Results = [System.Collections.ArrayList]::new()

        $VarCheck = [System.Collections.Generic.List[object]]($ChildHash, $SplatArgs) 
        foreach ($var in $VarCheck) {
            if (-not ([string]::IsNullOrEmpty($var))) {
                $ChildHash.Clear()
                $SplatArgs.Clear()
            }
        }
    }
    process {

        switch ($PSCmdlet.MyInvocation.BoundParameters["Method"]) {

            "DELETE" {

                [hashtable]$SplatArgs = [System.Collections.Specialized.OrderedDictionary]::new()
                [hashtable]$ChildHash = [System.Collections.Specialized.OrderedDictionary]::new()

                $ChildHash.Add('Authorization', "Bearer $($AccessToken)")
                if ($Headers) {
                    foreach ($key in $Headers.Keys) {
                        $ChildHash[$key] = $Headers[$key]
                    }
                }

                $SplatArgs.Add('Uri', [string]$Uri)    
                $SplatArgs.Add('Headers', $ChildHash)
                $SplatArgs.Add('Method', [string]$Method)

                Invoke-RestMethod @SplatArgs 
            }

            "GET" {
                   
                [hashtable]$SplatArgs = [System.Collections.Specialized.OrderedDictionary]::new()
                [hashtable]$ChildHash = [System.Collections.Specialized.OrderedDictionary]::new()

                $ChildHash.Add('Authorization', "Bearer $($AccessToken)")
                if ($Headers) {
                    foreach ($key in $Headers.Keys) {
                        $ChildHash[$key] = $Headers[$key]
                    }
                }

                $SplatArgs.Add('Uri', [string]$Uri)
                $SplatArgs.Add('Headers', $ChildHash)
                $SplatArgs.Add('Method', [string]$Method)

                do {
                    [array]$GraphResponse = Invoke-RestMethod @SplatArgs 
                    foreach ($Response in $GraphResponse.Value) {
                        [void]$Results.Add($Response)
                    }
                    $SplatArgs["Uri"] = $GraphResponse."@odata.nextLink"
                } while ($SplatArgs["Uri"])

                $Results

                if ([string]::IsNullOrEmpty($Results)) {
                    $SplatArgs["Uri"] = $Uri
                    Invoke-RestMethod @SplatArgs
                }
            }

            "POST" {

                if (-not ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Body"))) {
                    throw "You must include the -Body parameter when using the POST Method in the -Method Parameter"
                }

                [hashtable]$SplatArgs = [System.Collections.Specialized.OrderedDictionary]::new()
                [hashtable]$ChildHash = [System.Collections.Specialized.OrderedDictionary]::new()

                $ChildHash.Add('Authorization', "Bearer $($AccessToken)")
                if ($Headers) {
                    foreach ($key in $Headers.Keys) {
                        $ChildHash[$key] = $Headers[$key]
                    }
                }

                $SplatArgs.Add('Uri', [string]$Uri)
                $SplatArgs.Add('Headers', $ChildHash)
                $SplatArgs.Add('Method', [string]$Method)
                $SplatArgs.Add('ContentType', [string]'application/json')
                $SplatArgs.Add('Body', $Body)

                Invoke-RestMethod @SplatArgs 
            }

            "PUT" {

                if (-not ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Body"))) {
                    throw "You must include the -Body parameter when using the PUT Method in the -Method Parameter"
                }

                [hashtable]$SplatArgs = [System.Collections.Specialized.OrderedDictionary]::new()
                [hashtable]$ChildHash = [System.Collections.Specialized.OrderedDictionary]::new()

                $ChildHash.Add('Authorization', "Bearer $($AccessToken)")
                if ($Headers) {
                    foreach ($key in $Headers.Keys) {
                        $ChildHash[$key] = $Headers[$key]
                    }
                }

                $SplatArgs.Add('Uri', [string]$Uri)
                $SplatArgs.Add('Headers', $ChildHash)
                $SplatArgs.Add('Method', [string]$Method)
                $SplatArgs.Add('ContentType', [string]'application/json')
                $SplatArgs.Add('Body', $Body)

                Invoke-RestMethod @SplatArgs 
            }

            "PATCH" {

                if (-not ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Body"))) {
                    throw "You must include the -Body parameter when using the PATCH Method in the -Method Parameter"
                }

                [hashtable]$SplatArgs = [System.Collections.Specialized.OrderedDictionary]::new()
                [hashtable]$ChildHash = [System.Collections.Specialized.OrderedDictionary]::new()

                $ChildHash.Add('Authorization', "Bearer $($AccessToken)")
                if ($Headers) {
                    foreach ($key in $Headers.Keys) {
                        $ChildHash[$key] = $Headers[$key]
                    }
                }

                $SplatArgs.Add('Uri', [string]$Uri)
                $SplatArgs.Add('Headers', $ChildHash)
                $SplatArgs.Add('Method', [string]$Method)
                $SplatArgs.Add('ContentType', [string]'application/json')
                $SplatArgs.Add('Body', $Body)

                Invoke-RestMethod @SplatArgs 
            } 
        }
    }
    end {
        $ChildHash.Clear()
        $SplatArgs.Clear()
    }
}

Export-ModuleMember -Function Invoke-GraphAPIRequest