function Set-EaaResourceGroup {
	<#
	.SYNOPSIS
		Updates an Azure resource group.

	.DESCRIPTION
		Updates the managing resource or tags of an existing Azure resource group in the specified subscription.

	.PARAMETER Subscription
		The subscription name or ID containing the resource group.

	.PARAMETER Name
		The name of the resource group to update.

	.PARAMETER ManagedBy
		The resource ID, represented as a GUID, of the resource that manages this resource group.

	.PARAMETER Tags
		A hashtable of tag names and values that replaces the resource group's tags.

	.PARAMETER ServiceMap
		Optional hashtable to map service names to specific EntraAuth service instances.
		Used for advanced scenarios where you want to use something other than the default Azure connection.
		Example: @{ Azure = 'MyAzure' }
		This will switch all Azure API calls to use the configuration defined in MyAzure.

	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

	.EXAMPLE
		PS C:\> Set-EaaResourceGroup -Subscription 'Production' -Name 'WebApps' -Tags @{ Environment = 'Prod'; Owner = 'Platform' }

		Updates the WebApps resource group in the Production subscription with the specified Environment and Owner tags.
	#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfArgumentCompleter('EntraAuth.Azure.Subscription')]
		[string]
		$Subscription,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfValidatePattern('^[-\w\._\(\)]{1,90}$', ErrorMessage = 'Resource Groups must not be longer than 90 characters, not contain whitespace or special characters!')]
		[string]
		$Name,

		[string]
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

		if (-not ($ManagedBy -or $Tags)) {
			Stop-PSFFunction -Message "Neither 'ManagedBy' nor 'Tags' were specified, no change possible" -EnableException $true -Cmdlet $PSCmdlet -Category InvalidOperation
		}
	}
	process {
		$subscriptionID = Resolve-Subscription -Name $Subscription -Services $services -Cmdlet $PSCmdlet
		$body = @{ }
		if ($ManagedBy) { $body.managedBy = $ManagedBy }
		if ($Tags) { $body.tags = $Tags }

		Invoke-PSFProtectedCommand -Action "Updating Resource Group $Name under Subscription $SubscriptionID" -Target $Name -ScriptBlock {
			Invoke-EntraRequest -Service $services.Azure -Method PATCH -Path "subscriptions/$subscriptionID/resourcegroups/$Name" -Query @{
				'api-version' = '2021-04-01'
			} -Body $body -ContentType 'application/json' | ConvertTo-ResourceGroup -SubscriptionID $subscriptionID
		} -EnableException $true -PSCmdlet $PSCmdlet
	}
}