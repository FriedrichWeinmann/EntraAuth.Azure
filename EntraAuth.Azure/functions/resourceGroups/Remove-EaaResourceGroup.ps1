function Remove-EaaResourceGroup {
	<#
	.SYNOPSIS
		Removes an Azure resource group.

	.DESCRIPTION
		Deletes the specified resource group from an Azure subscription.

	.PARAMETER Subscription
		The subscription name or ID containing the resource group.

	.PARAMETER Name
		The name of the resource group to remove.

	.PARAMETER ForceDeletion
		One or more Azure resource types for which deletion is forced when removing the resource group.

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
		PS C:\> Remove-EaaResourceGroup -Subscription 'Development' -Name 'Temporary' -Confirm:$false

		Removes the Temporary resource group from the Development subscription without prompting for confirmation.
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

		[PsfArgumentCompleter('EntraAuth.Azure.ResourceGroup.ForceDeletion')]
		[string[]]
		$ForceDeletion,

		[ServiceTransformAttribute()]
		[hashtable]
		$ServiceMap = @{}
	)
	begin {
		$services = $script:_serviceSelector.GetServiceMap($ServiceMap)
		Assert-EntraConnection -Cmdlet $PSCmdlet -Service $services.Azure
	}
	process {
		$subscriptionID = Resolve-Subscription -Name $Subscription -Services $services -Cmdlet $PSCmdlet
		$query = @{
			'api-version' = '2021-04-01'
		}
		if ($ForceDeletion) { $query.forceDeletionTypes = $ForceDeletion -join ',' }
		Invoke-PSFProtectedCommand -Action "Deleting Resource Group $Name under Subscription $SubscriptionID" -Target $Name -ScriptBlock {
			$null = Invoke-EntraRequest -Service $services.Azure -Method DELETE -Path "subscriptions/$subscriptionID/resourcegroups/$Name" -Query $query
		} -EnableException $true -PSCmdlet $PSCmdlet
	}
}