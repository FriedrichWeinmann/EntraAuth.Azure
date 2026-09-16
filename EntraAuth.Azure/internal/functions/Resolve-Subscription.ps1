function Resolve-Subscription {
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