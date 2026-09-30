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