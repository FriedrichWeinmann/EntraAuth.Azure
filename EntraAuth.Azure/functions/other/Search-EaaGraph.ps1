function Search-EaaGraph {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Query,

		[string[]]
		$Subscriptions,
		
		[string[]]
		$ManagementGroups,

		[ValidateRange(1, 1000)]
		[int]
		$Top,
		
		[ValidateRange(0, 2147483647)]
		[int]
		$Skip,

		[string]
		$SkipToken,

		[ValidateSet('table', 'objectArray')]
		[string]
		$ResultFormat,

		[ValidateSet('AtScopeAndBelow', 'AtScopeAndAbove', 'AtScopeExact', 'AtScopeAboveAndBelow')]
		[string]
		$AuthorizationScopeFilter,

		[switch]
		$AllowPartialScopes,

		[hashtable]
		$Options,

		[object[]]
		$Facets,

		[ServiceTransformAttribute()]
		[hashtable]
		$ServiceMap = @{}
	)
	begin {
		$services = $script:_serviceSelector.GetServiceMap($ServiceMap)
		Assert-EntraConnection -Cmdlet $PSCmdlet -Service $services.Azure
	}
	process {
		$body = @{
			query = $Query
		}
		if ($Facets) { $body.facets = $Facets }
		if ($ManagementGroups) { $body.managementGroups = $ManagementGroups }
		if ($Subscriptions) { $body.subscriptions = $Subscriptions }

		$optionsHash = @{}
		if ($Options) { $optionsHash = $Options }
		if ($PSBoundParameters.Keys -contains 'Top') { $optionsHash['$top'] = $Top }
		if ($PSBoundParameters.Keys -contains 'Skip') { $optionsHash['$skip'] = $Skip }
		if ($SkipToken) { $optionsHash['$skipToken'] = $SkipToken }
		if ($ResultFormat) { $optionsHash['resultFormat'] = $ResultFormat }
		if ($AuthorizationScopeFilter) { $optionsHash['authorizationScopeFilter'] = $AuthorizationScopeFilter }
		if ($AllowPartialScopes) { $optionsHash['allowPartialScopes'] = $true }
		if ($optionsHash.Count -gt 0) { $body.options = $optionsHash }

		Invoke-EntraRequest -Service $services.Azure -Method POST -Path 'providers/Microsoft.ResourceGraph/resources' -Query @{
			'api-version' = '2024-04-01'
		} -Body $body -ContentType 'application/json'
	}
}