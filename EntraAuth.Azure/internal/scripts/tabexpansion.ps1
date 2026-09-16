Register-PSFTeppScriptblock -Name 'EntraAuth.Azure.ResourceGroup.ForceDeletion' -ScriptBlock {
	'Microsoft.Compute/virtualMachines'
	'Microsoft.Compute/virtualMachineScaleSets'
} -Global

Register-PSFTeppScriptblock -Name 'EntraAuth.Azure.Subscription' -ScriptBlock {
	$param = @{}
	if ($fakeBoundParameter.ServiceMap) { $param.ServiceMap = $fakeBoundParameter.ServiceMap }

	Get-EaaSubscription @param | ForEach-Object {
		@{
			Text         = $_.SubscriptionID
			ListItemText = $_.DisplayName
			Tooltip      = $_.DisplayName
		}
	}
} -Global

Register-PSFTeppScriptblock -Name 'EntraAuth.Azure.Location' -ScriptBlock {
	if (-not $fakeBoundParameter.Subscription) { return }

	$param = @{
		Subscription = $fakeBoundParameter.Subscription
	}
	if ($fakeBoundParameter.ServiceMap) { $param.ServiceMap = $fakeBoundParameter.ServiceMap }

	Get-EaaLocation @param | ForEach-Object {
		@{
			Text         = $_.name
			ListItemText = $_.DisplayName
			Tooltip      = '{0} ({1}) | {2}' -f $_.DisplayName, $_.Name, $_.Category
		}
	}
}

Register-PSFTeppScriptblock -Name 'EntraAuth.Azure.ResourceGroup' -ScriptBlock {
	if (-not $fakeBoundParameter.Subscription) { return }

	$param = @{
		Subscription = $fakeBoundParameter.Subscription
	}
	if ($fakeBoundParameter.ServiceMap) { $param.ServiceMap = $fakeBoundParameter.ServiceMap }

	Get-EaaResourceGroup @param | ForEach-Object {
		@{
			Text         = $_.Name
			ListItemText = $_.Name
			Tooltip      = '{0} ({1})' -f $_.Name, $_.Location
		}
	}
}