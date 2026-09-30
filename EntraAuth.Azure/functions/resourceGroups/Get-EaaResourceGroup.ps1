function Get-EaaResourceGroup {
	<#
	.SYNOPSIS
		Retrieves Azure resource groups from a subscription.

	.DESCRIPTION
		Retrieves a resource group by name or lists resource groups in the specified Azure subscription. List results can be limited by tag conditions, an Azure filter expression, or a maximum result count.

	.PARAMETER Subscription
		The subscription name or ID from which resource groups are retrieved.

	.PARAMETER Name
		The exact name of the resource group to retrieve.

	.PARAMETER Tag
		A hashtable of tag name and value used to filter listed resource groups.
		Must not contain more than one tag!

		Example:
		@{ Environment = 'Prod' }
		This will find all Resource Groups in the 'Prod' environment.

	.PARAMETER Filter
		An Azure filter expression appended to any conditions supplied through Tags.

		Example:
		Environment eq 'Prod' or Generation eq '3'

	.PARAMETER Top
		The maximum number of resource groups requested from Azure.

	.PARAMETER ServiceMap
		Optional hashtable to map service names to specific EntraAuth service instances.
		Used for advanced scenarios where you want to use something other than the default Azure connection.
		Example: @{ Azure = 'MyAzure' }
		This will switch all Azure API calls to use the configuration defined in MyAzure.

	.EXAMPLE
		PS C:\> Get-EaaResourceGroup -Subscription 'Production' -Name 'WebApps'

		Retrieves the resource group named WebApps from the Production subscription.

	.EXAMPLE
		PS C:\> Get-EaaResourceGroup -Subscription '00000000-0000-0000-0000-000000000001' -Tags @{ Environment = 'Prod' } -Top 20

		Lists up to 20 resource groups in the 00000000-0000-0000-0000-000000000001 subscription whose Environment tag equals Prod.
	#>
	[CmdletBinding(DefaultParameterSetName = 'Filter')]
	param (
		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('EntraAuth.Azure.Subscription')]
		[string]
		$Subscription,

		[Parameter(ParameterSetName = 'ByName')]
		[PsfValidatePattern('^[-\w\._\(\)]{1,90}$', ErrorMessage = 'Resource Groups must not be longer than 90 characters, not contain whitespace or special characters!')]
		[string]
		$Name,

		[Parameter(ParameterSetName = 'Filter')]
		[PsfValidateScript({ $_.Count -lt 2 }, ErrorMessage = 'Cannot specify more than one tag!')]
		[hashtable]
		$Tag,
		
		[Parameter(ParameterSetName = 'Filter')]
		[string]
		$Filter,
		
		[Parameter(ParameterSetName = 'Filter')]
		[int]
		$Top,

		[ServiceTransformAttribute()]
		[hashtable]
		$ServiceMap = @{}
	)

	begin {
		$services = $script:_serviceSelector.GetServiceMap($ServiceMap)
		Assert-EntraConnection -Cmdlet $PSCmdlet -Service $services.Azure
		$subscriptionID = Resolve-Subscription -Name $Subscription -Services $services -Cmdlet $PSCmdlet
	}
	process {
		if ($Name) {
			Invoke-EntraRequest -Service $services.Azure -Path "subscriptions/$subscriptionID/resourcegroups/$Name" -Query @{
				'api-version' = '2021-04-01'
			} | ConvertTo-ResourceGroup -SubscriptionID $subscriptionID
			return
		}

		$query = @{
			'api-version' = '2021-04-01'
		}
		if ($PSBoundParameters.Keys -contains 'Top') { $query.'$top' = $Top }

		if ($Filter) { $query['$filter'] = $Filter }
		elseif ($Tag) { $query['$filter'] = "tagName eq '$($Tag.Keys[0])' and tagValue eq '$($Tag.Values[0])'" }

		Invoke-EntraRequest -Service $services.Azure -Path "subscriptions/$subscriptionID/resourcegroups" -Query $query | ConvertTo-ResourceGroup -SubscriptionID $subscriptionID
	}
}