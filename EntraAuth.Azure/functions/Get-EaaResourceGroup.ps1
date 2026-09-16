function Get-EaaResourceGroup {
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
		[hashtable]
		$Tags,
		
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
		if ($PSBoundParameters.Keys -contains 'Top') { $query.Top = $Top }

		$filterB = New-EntraFilterBuilder
		foreach ($tagName in $Tags.Keys) {
			$filterB.Add($tagName, 'eq', $Tags.$tagName)
		}
		if ($Filter) { $filterB.Add($Filter) }
		if ($filterB.Entries.Count -gt 0) { $query['$filter'] = $filterB.ToString() }

		Invoke-EntraRequest -Service $services.Azure -Path "subscriptions/$subscriptionID/resourcegroups/$Name" -Query $query | ConvertTo-ResourceGroup -SubscriptionID $subscriptionID
	}
}