function Get-EaaSubscription {
	<#
	.SYNOPSIS
		Lists the available subscriptions in the tenant.
	
	.DESCRIPTION
		Lists the available subscriptions in the tenant.
	
	.PARAMETER Name
		A wildcard pattern used to filter subscription display names.
		Defaults to: *
	
	.PARAMETER ID
		The subscription ID of the subscription to retrieve.
	
	.PARAMETER ServiceMap
		Optional hashtable to map service names to specific EntraAuth service instances.
		Used for advanced scenarios where you want to use something other than the default Azure connection.
		Example: @{ Azure = 'MyAzure' }
		This will switch all Azure API calls to use the configuration defined in MyAzure.
	
	.EXAMPLE
		PS C:\> Get-EaaSubscription -Name 'Production*'

		Lists subscriptions in the currently connected tenant whose display names begin with Production.

	.EXAMPLE
		PS C:\> Get-EaaSubscription -ID '00000000-0000-0000-0000-000000000001'

		Retrieves the subscription with the specified subscription ID.
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