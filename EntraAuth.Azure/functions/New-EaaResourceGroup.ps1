function New-EaaResourceGroup {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('EntraAuth.Azure.Subscription')]
		[string]
		$Subscription,

		[Parameter(Mandatory = $true)]
		[PsfValidatePattern('^[-\w\._\(\)]{1,90}$', ErrorMessage = 'Resource Groups must not be longer than 90 characters, not contain whitespace or special characters!')]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('EntraAuth.Azure.Location')]
		[string]
		$Location,

		[guid]
		$ManagedBy,

		[hashtable]
		$Tags,

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
		$body = @{
			location = $Location
		}
		if ($ManagedBy) { $body.managedBy = $ManagedBy }
		if ($Tags) { $body.tags = $Tags }

		Invoke-PSFProtectedCommand -Action "Create Resource Group $Name in $Location under Subscription $SubscriptionID" -Target $Name -ScriptBlock {
			Invoke-EntraRequest -Service $services.Azure -Method PUT -Path "subscriptions/$subscriptionID/resourcegroups/$Name" -Query @{
				'api-version' = '2021-04-01'
			} -Body $body -ContentType 'application/json' | ConvertTo-ResourceGroup -SubscriptionID $subscriptionID
		} -EnableException $true -PSCmdlet $PSCmdlet
	}
}