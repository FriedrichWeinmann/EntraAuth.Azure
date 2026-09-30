function Search-EaaGraph {
	<#
	.SYNOPSIS
		Queries Azure Resource Graph for resources across subscriptions or management groups.

	.DESCRIPTION
		Submits an Azure Resource Graph KQL query and returns matching resources.
		This allows high performance query against deployed resources.

		The query can target selected subscriptions or management groups and can control paging, result formatting, authorization scope, partial-scope behavior, query options, and facets.

	.PARAMETER Query
		The Azure Resource Graph query to execute.
		This adheres to the KQL query syntax.

		See the Resource graph explorer for a visual tool to discover tables and design tables:
		https://portal.azure.com/#servicemenu/Microsoft_Azure_Resources/ResourceManager/resourcegraphexplorer

	.PARAMETER Subscriptions
		The subscription IDs in which to run the query.

	.PARAMETER ManagementGroups
		The management group IDs in which to run the query.

	.PARAMETER Top
		The maximum number of results to return. Valid values are 1 through 1000.

	.PARAMETER Skip
		The number of matching results to skip. Valid values are 0 through 2147483647.

	.PARAMETER SkipToken
		A continuation token returned by a previous query, used to retrieve the next page of results.

	.PARAMETER ResultFormat
		The response format. Valid values are table and objectArray.

	.PARAMETER AuthorizationScopeFilter
		The authorization scope relationship used to filter authorization resources.

	.PARAMETER AllowPartialScopes
		Allows the query to return partial results when the requested subscription count exceeds Azure Resource Graph limits.

	.PARAMETER Options
		Additional Azure Resource Graph query options.
		See here for the definition:
		https://learn.microsoft.com/en-us/rest/api/azureresourcegraph/resourcegraph/resources/resources?view=rest-azureresourcegraph-resourcegraph-2024-04-01&tabs=HTTP#queryrequestoptions

		Allows defining the options in one hashtable, rather than using the explicit parameters provided separately:
		Top, Skip, SkipToken, ResultFormat, AuthorizationScopeFilter, and AllowPartialScopes.
		If defining both, the explicit parameters win.

	.PARAMETER Facets
		Facet expressions to calculate and include with the query results.

	.PARAMETER ServiceMap
		Optional hashtable to map service names to specific EntraAuth service instances.
		Used for advanced scenarios where you want to use something other than the default Azure connection.
		Example: @{ Azure = 'MyAzure' }
		This will switch all Azure API calls to use the configuration defined in MyAzure.
		Defaults to: @{}

	.EXAMPLE
		PS C:\> Search-EaaGraph -Query "Resources | where type =~ 'microsoft.compute/virtualmachines'" -Subscriptions '00000000-0000-0000-0000-000000000001' -Top 100

		Queries the specified subscription for up to 100 virtual machines and returns the Azure Resource Graph response.

	.EXAMPLE
		PS C:\> Search-EaaGraph -Query "Resources | where type =~ 'microsoft.compute/virtualmachines'" -Top 100

		Queries all subscriptions for up to 100 virtual machines and returns the Azure Resource Graph response.

	.LINK
		https://learn.microsoft.com/en-us/rest/api/azureresourcegraph/resourcegraph/resources/resources

	.LINK
		https://azure.microsoft.com/en-us/get-started/azure-portal/resource-graph

	.LINK
		https://portal.azure.com/#servicemenu/Microsoft_Azure_Resources/ResourceManager/resourcegraphexplorer
	#>
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

		# Used to ensure proper casing
		$formatMap = @{
			table       = 'table'
			objectArray = 'objectArray'
		}
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
		if ($ResultFormat) { $optionsHash['resultFormat'] = $formatMap[$ResultFormat] }
		if ($AuthorizationScopeFilter) { $optionsHash['authorizationScopeFilter'] = $AuthorizationScopeFilter }
		if ($AllowPartialScopes) { $optionsHash['allowPartialScopes'] = $true }
		if ($optionsHash.Count -gt 0) { $body.options = $optionsHash }

		Invoke-EntraRequest -Service $services.Azure -Method POST -Path 'providers/Microsoft.ResourceGraph/resources' -Query @{
			'api-version' = '2024-04-01'
		} -Body $body -ContentType 'application/json'
	}
}