function ConvertTo-Subscription {
	<#
	.SYNOPSIS
		Converts Azure API subscription data into EntraAuth.Azure.Subscription objects.

	.DESCRIPTION
		Transforms subscription data returned by the Azure API into EntraAuth.Azure.Subscription objects with normalized subscription, tenant, state, authorization, and policy properties while preserving the original object.

	.PARAMETER InputObject
		The Azure API subscription object to convert.

	.EXAMPLE
		PS C:\> $response | ConvertTo-Subscription

		Converts each subscription in the Azure API response into an EntraAuth.Azure.Subscription object.
	#>
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