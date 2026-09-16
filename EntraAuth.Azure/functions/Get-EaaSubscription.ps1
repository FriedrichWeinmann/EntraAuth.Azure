function Get-EaaSubscription {
	<#
	.SYNOPSIS
		Lists the available subscriptions in the tenant.
	
	.DESCRIPTION
		Lists the available subscriptions in the tenant.
	
	.PARAMETER Name
		Name of the subscription to filter by.
		Defaults to: *
	
	.PARAMETER ID
		Retrieve the specified subscription by its SubscriptionID
	
	.PARAMETER ServiceMap
		Optional hashtable to map service names to specific EntraAuth service instances.
		Used for advanced scenarios where you want to use something other than the default Azure connection.
		Example: @{ Azure = 'MyAzure' }
		This will switch all Azure API calls to use the MyAzure service configuration.
	
	.EXAMPLE
		PS C:\> Get-EaaSubscription

		Lists all available subscriptions in the currently connected tenant.
	#>
	[CmdletBinding(DefaultParameterSetName = 'ByName')]
	param (
		[Parameter(ParameterSetName = 'ByName')]
		[PsfArgumentCompleter('EntraAuth.Azure.Subscription')]
		[string]
		$Name = '*',

		[Parameter(Mandatory = $true, ParameterSetName = 'ByID')]
		[guid]
		$ID,

		[ServiceTransformAttribute()]
		[hashtable]
		$ServiceMap = @{}
	)

	begin {
		$services = $script:_serviceSelector.GetServiceMap($ServiceMap)
		Assert-EntraConnection -Cmdlet $PSCmdlet -Service $services.Azure

		function ConvertTo-Subscription {
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				$InputObject
			)
			process {
				if (-not $InputObject) { return }

				[PSCustomObject]@{
					PSTypeName           = 'EntraAuth.Azure.Subscription'
					DisplayName          = $InputObject.DisplayName
					ID                   = $InputObject.id
					SubscriptionID       = $InputObject.SubscriptionID
					TenantID             = $InputObject.TenantID
					State                = $InputObject.state
					AuthorizationSource  = $InputObject.authorizationSource
					ManagedByTenants     = $InputObject.managedByTenants
					SubscriptionPolicies = $InputObject.subscriptionPolicies

					Object               = $InputObject
				}
			}
		}
	}
	process {
		if ($ID) {
			Invoke-EntraRequest -Service $services.Azure -Path "subscriptions/$ID" -Query @{
				'api-version' = '2022-12-01'
			} | ConvertTo-Subscription
			return
		}

		Invoke-EntraRequest -Service $services.Azure -Path 'subscriptions' -Query @{
			'api-version' = '2022-12-01'
		} | Where-Object displayName -Like $Name | ConvertTo-Subscription
	}
}