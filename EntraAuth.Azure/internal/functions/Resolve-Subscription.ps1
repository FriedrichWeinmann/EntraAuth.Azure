function Resolve-Subscription {
	<#
	.SYNOPSIS
		Resolves a subscription name or ID to a subscription ID.

	.DESCRIPTION
		Returns a supplied subscription ID unchanged or resolves an exact subscription display name through Azure. Name resolution succeeds only when exactly one subscription matches and reports an error through the calling cmdlet for missing or ambiguous names.

	.PARAMETER Name
		The subscription display name or subscription ID to resolve.

	.PARAMETER Services
		A hashtable containing the service mappings used to query subscriptions.

	.PARAMETER Cmdlet
		The calling cmdlet context used to report resolution errors.

	.EXAMPLE
		PS C:\> Resolve-Subscription -Name 'Production' -Services $services -Cmdlet $PSCmdlet

		Resolves the subscription whose display name is Production using the supplied services and returns its subscription ID, reporting any resolution error through the calling cmdlet.
	#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[hashtable]
		$Services,

		[Parameter(Mandatory = $true)]
		$Cmdlet
	)
	process {
		# We don't validate GUIDs - we assume the user knew better
		# Presumably, bad input would still only lead to subsequent request failing
		if ($Name -as [guid]) { return $Name }

		$subscriptions = Get-EaaSubscription -ServiceMap $Services | Where-Object DisplayName -EQ $Name
		if (@($subscriptions).Count -eq 1) {
			return $subscriptions.SubscriptionID
		}
		if (@($subscriptions).Count -gt 1) {
			Stop-PSFFunction -Message "Ambiguous Subscription! $Name resolved to $(@($subscriptions).Count) subscriptions ($($subscriptions.SubscriptionID -join ', '))" -Cmdlet $Cmdlet -EnableException $true
		}
		Stop-PSFFunction -Message "Invalid Subscription! $Name could not be resolved" -Cmdlet $Cmdlet -EnableException $true
	}
}