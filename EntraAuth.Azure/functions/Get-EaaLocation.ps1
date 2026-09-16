function Get-EaaLocation {
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