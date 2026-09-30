function Get-EaaLocation {
	<#
	.SYNOPSIS
		Lists Azure locations available to a subscription.

	.DESCRIPTION
		Retrieves the Azure locations available to the specified subscription and returns location objects with display, regional, category, pairing, availability zone, and source metadata. Results can be filtered by name and can include Azure extended locations.

	.PARAMETER Subscription
		The subscription name or ID whose available locations are retrieved.

	.PARAMETER Name
		A wildcard pattern used to filter location names.
		Defaults to: *

	.PARAMETER IncludeExtended
		Includes extended locations in the Azure API response when specified.

	.PARAMETER ServiceMap
		Optional hashtable to map service names to specific EntraAuth service instances.
		Used for advanced scenarios where you want to use something other than the default Azure connection.
		Example: @{ Azure = 'MyAzure' }
		This will switch all Azure API calls to use the configuration defined in MyAzure.

	.EXAMPLE
		PS C:\> Get-EaaLocation -Subscription '00000000-0000-0000-0000-000000000001' -Name 'eastus*' -IncludeExtended

		Retrieves standard and extended locations whose names begin with eastus for the specified subscription.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('EntraAuth.Azure.Subscription')]
		[string]
		$Subscription,

		[string]
		$Name = '*',

		[switch]
		$IncludeExtended,

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
		$query = @{
			'api-version' = '2022-12-01'
		}
		if ($IncludeExtended) { $query.includeExtendedLocations = $true }

		Invoke-EntraRequest -Service $services.Azure -Path "subscriptions/$subscriptionID/locations" -Query $query | Where-Object name -Like $Name | ForEach-Object {
			[PSCustomObject]@{
				PSTypeName               = 'EntraAuth.Azure.Location'
				ID                       = $_.id
				Name                     = $_.name
				DisplayName              = $_.displayName
				RegionalDisplayName      = $_.regionalDisplayName
				Category                 = $_.metadata.regionCategory
				PairedRegion             = $_.metadata.pairedRegion.name
				Metadata                 = $_.metadata
				AvailabilityZoneMappings = $_.availabilityZoneMappings
				SubscriptionID           = $subscriptionID

				Object                   = $_
			}
		}
	}
}